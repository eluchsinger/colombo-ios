import Foundation
import CoreLocation

class WikipediaLocationManager {
    private let baseURL = "https://en.wikipedia.org/w/api.php"
    
    func fetchNearbyArticles(coordinate: CLLocationCoordinate2D, radius: Int = 100, limit: Int = 10) async throws -> [WikipediaLocation] {
        var components = URLComponents(string: baseURL)
        components?.queryItems = [
            URLQueryItem(name: "action", value: "query"),
            URLQueryItem(name: "list", value: "geosearch"),
            URLQueryItem(name: "gscoord", value: "\(coordinate.latitude)|\(coordinate.longitude)"),
            URLQueryItem(name: "gsradius", value: String(radius)),
            URLQueryItem(name: "gslimit", value: String(limit)),
            URLQueryItem(name: "format", value: "json")
        ]
        
        guard let url = components?.url else {
            throw WikipediaError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(WikipediaResponse.self, from: data)
        return response.query.geosearch
    }
}

enum WikipediaError: Error {
    case invalidURL
}
