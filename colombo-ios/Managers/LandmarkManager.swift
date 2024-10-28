//
//  LandmarkManager.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 28.10.2024.
//
import Foundation
import OSLog
import Supabase
import SwiftUI

/// A structure representing a landmark in the database
struct DatabaseLandmark: Decodable {
    let id: Int
    let mapboxId: String
    let placeName: String

    enum CodingKeys: String, CodingKey {
        case id
        case mapboxId = "mapbox_id"
        case placeName = "place_name"
    }
}

/// A manager class responsible for fetching landmarks from Supabase database
@MainActor
class LandmarkManager: ObservableObject {
    private let client: SupabaseClient
    private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!, category: "LandmarkManager")

    @Published private(set) var isLoading = false

    init(client: SupabaseClient) {
        self.client = client
    }

    func getPlace(mapboxId: String) async throws -> DatabaseLandmark? {
        await MainActor.run {
            isLoading = true
        }

        defer {
            Task { @MainActor in
                isLoading = false
            }
        }

        logger.debug("Fetching place with mapboxId: \(mapboxId)")

        let query =
            client
            .from("places")
            .select("id, mapbox_id, place_name")
            .eq("mapbox_id", value: mapboxId)

        do {
            let response: [DatabaseLandmark] = try await query.execute().value
            if let place = response.first {
                logger.debug(
                    "Found place: id=\(place.id), mapboxId=\(place.mapboxId), name=\(place.placeName)"
                )
            } else {
                logger.debug("No place found for mapboxId: \(mapboxId)")
            }

            return response.first
        } catch {
            dump(error)
            return nil
        }
    }
}
