import ActivityKit
import Foundation

struct LandmarkActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var landmarkName: String
        var distance: Double
    }
    
    var initialLandmarkName: String
}