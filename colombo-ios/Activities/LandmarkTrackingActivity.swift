import ActivityKit
import Foundation

@MainActor
class LandmarkTrackingActivity: ObservableObject {
    private var activity: Activity<LandmarkActivityAttributes>?
    
    func startTracking(landmarkName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            print("❌ Live Activities not enabled")
            return 
        }
        
        let attributes = LandmarkActivityAttributes(initialLandmarkName: landmarkName)
        let contentState = LandmarkActivityAttributes.ContentState(
            landmarkName: landmarkName,
            distance: 0
        )
        
        do {
            let staleDate = Date().addingTimeInterval(30 * 60) // Reduced to 30 minutes for testing
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: staleDate)
            )
            print("✅ Live Activity started for \(landmarkName)")
        } catch {
            print("❌ Error starting activity: \(error)")
        }
    }
    
    func updateActivity(landmarkName: String, distance: Double) {
        Task {
            let updatedState = LandmarkActivityAttributes.ContentState(
                landmarkName: landmarkName,
                distance: distance
            )
            
            await activity?.update(.init(state: updatedState, staleDate: nil))
            print("📍 Updated activity: \(landmarkName) - \(distance)m")
        }
    }
    
    func stopTracking() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
        }
    }
}