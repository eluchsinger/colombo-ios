//
//  PlaceVisitRequest.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 28.10.2024.
//

import Foundation

struct PlaceVisitRequest: Encodable {
    let place: PlaceInfo
    let language: String?

    struct PlaceInfo: Encodable {
        let mapBoxId: String?
        let mapKitId: String?
        let text: String
        let location: String
        let placeName: String?
        let relevance: Double?
        let properties: Properties?

        struct Properties: Encodable {
            let category: String?
            let landmark: Bool?
        }

        enum CodingKeys: String, CodingKey {
            case mapBoxId = "mapBoxId"
            case mapKitId = "mapKitId"
            case text
            case location
            case placeName = "place_name"
            case relevance
            case properties
        }
    }
}

struct PlaceVisitResponse: Decodable {
    let placeName: String
    let subtitle: String?
    let storyText: String
    let audioUri: String
}

enum PlaceVisitError: Error {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case unauthorized
    case missingData
    case serverError
    case decodingError

    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid server response"
        case .unauthorized:
            return "Unauthorized access"
        case .missingData:
            return "Missing required data"
        case .serverError:
            return "Server error"
        case .decodingError:
            return "Error parsing server response"
        }
    }
}

class PlaceVisitService {
    static let shared = PlaceVisitService()
    private let baseURL = "https://colombo.guide"

    private init() {}

    func visitPlace(landmark: LandmarkItem, language: String? = nil)
        async throws -> PlaceVisitResponse
    {
        guard let url = URL(string: "\(baseURL)/api/places/visit") else {
            throw PlaceVisitError.invalidURL
        }

        // Get the Supabase token
        guard let session = try? await supabase.auth.session else {
            throw PlaceVisitError.unauthorized
        }

        let coordinates = landmark.mapItem.placemark.coordinate
        let location = "\(coordinates.latitude),\(coordinates.longitude)"

        let request = PlaceVisitRequest(
            place: .init(
                mapBoxId: nil,
                mapKitId: landmark.mapItem.identifier?.rawValue,
                text: landmark.mapItem.name ?? "",
                location: location,
                placeName: landmark.mapItem.name,
                relevance: nil,
                properties: .init(category: nil, landmark: true)
            ),
            language: language
        )

        // Log the request payload
        if let jsonData = try? JSONEncoder().encode(request),
            let jsonString = String(data: jsonData, encoding: .utf8)
        {
            print("📤 Request payload:")
            print(jsonString)

            // Pretty print for better readability
            if let jsonObject = try? JSONSerialization.jsonObject(
                with: jsonData),
                let prettyJsonData = try? JSONSerialization.data(
                    withJSONObject: jsonObject, options: .prettyPrinted),
                let prettyJsonString = String(
                    data: prettyJsonData, encoding: .utf8)
            {
                print("\nPretty printed:")
                print(prettyJsonString)
            }
        }

        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue(
            "Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization"
        )
        urlRequest.setValue(
            "application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = try? JSONEncoder().encode(request)
        urlRequest.timeoutInterval = 30

        do {
            let (data, response) = try await URLSession.shared.data(
                for: urlRequest)

            // Log the response
            print(
                "\n📥 Response status: \((response as? HTTPURLResponse)?.statusCode ?? -1)"
            )
            if let jsonObject = try? JSONSerialization.jsonObject(with: data),
                let prettyJsonData = try? JSONSerialization.data(
                    withJSONObject: jsonObject, options: .prettyPrinted),
                let prettyJsonString = String(
                    data: prettyJsonData, encoding: .utf8)
            {
                print("Response body:")
                print(prettyJsonString)
            }

            guard let httpResponse = response as? HTTPURLResponse else {
                throw PlaceVisitError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200:
                let decoder = JSONDecoder()
                return try decoder.decode(PlaceVisitResponse.self, from: data)
            case 400:
                throw PlaceVisitError.missingData
            case 401:
                throw PlaceVisitError.unauthorized
            case 500:
                throw PlaceVisitError.serverError
            case 408:
                throw PlaceVisitError.networkError(
                    NSError(
                        domain: "PlaceVisitService", code: 408,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Request timed out. Please try again."
                        ]))
            default:
                throw PlaceVisitError.invalidResponse
            }
        } catch {
            if (error as NSError).code == NSURLErrorTimedOut {
                throw PlaceVisitError.networkError(
                    NSError(
                        domain: "PlaceVisitService", code: NSURLErrorTimedOut,
                        userInfo: [
                            NSLocalizedDescriptionKey:
                                "Request timed out. Please try again."
                        ]))
            }
            throw PlaceVisitError.networkError(error)
        }
    }
}
