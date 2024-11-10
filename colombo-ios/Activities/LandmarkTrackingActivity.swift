import ActivityKit
import Foundation

@MainActor
class LandmarkTrackingActivity: ObservableObject {
    private var activity: Activity<LandmarkActivityAttributes>?
    
    func startTracking(landmarkName: String) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }
        
        let attributes = LandmarkActivityAttributes(initialLandmarkName: landmarkName)
        let contentState = LandmarkActivityAttributes.ContentState(
            landmarkName: landmarkName,
            distance: 0
        )
        
        do {
            let staleDate = Date().addingTimeInterval(24 * 60 * 60) // 24 hours from now
            activity = try Activity.request(
                attributes: attributes,
                content: .init(state: contentState, staleDate: staleDate)
            )
        } catch {
            print("Error starting activity: \(error)")
        }
    }
    
    func updateActivity(landmarkName: String, distance: Double) {
        Task {
            let updatedState = LandmarkActivityAttributes.ContentState(
                landmarkName: landmarkName,
                distance: distance
            )
            
            await activity?.update(.init(state: updatedState, staleDate: nil))
        }
    }
    
    func stopTracking() {
        Task {
            await activity?.end(nil, dismissalPolicy: .immediate)
        }
    }
}