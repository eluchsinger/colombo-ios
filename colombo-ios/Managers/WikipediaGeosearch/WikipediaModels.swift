import Foundation

struct WikipediaResponse: Codable {
    let query: WikipediaQuery
}

struct WikipediaQuery: Codable {
    let geosearch: [WikipediaLocation]
}

struct WikipediaLocation: Codable {
    let pageid: Int
    let title: String
    let lat: Double
    let lon: Double
    let dist: Double
    
    enum CodingKeys: String, CodingKey {
        case pageid, title, lat, lon, dist
    }
}
