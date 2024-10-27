import Foundation
import CoreLocation
import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastFetchTime: Date?
    private let fetchInterval: TimeInterval = 5 // Minimum time between fetches in seconds

    @Published var location: CLLocationCoordinate2D? = nil
    @Published var locationError: String? = nil
    @Published var pointsOfInterest: [MKMapItem] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else { return }
        if location == nil || location!.distance(to: latestLocation.coordinate) > 50 {
            location = latestLocation.coordinate
            fetchPOIsWithThrottle() // Throttled fetch function
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        locationError = error.localizedDescription
    }

    private func fetchPOIsWithThrottle() {
        // Throttle requests by checking the time since the last fetch
        let now = Date()
        if let lastFetchTime = lastFetchTime, now.timeIntervalSince(lastFetchTime) < fetchInterval {
            return // Skip this fetch if it's too soon after the last one
        }
        lastFetchTime = now
        fetchPOIs() // Fetch POIs if sufficient time has passed
    }
    
    /// Fetch the POIs around the user's current location.
    /// - Parameter radius: The radius of the POIs around the user's location.
    func fetchPOIs(radius: CLLocationDistance = 10) {
        guard let location = location else { return }

        // Log each POI fetch attempt with a fixed 10-meter radius
        print("Fetching POIs at location (\(location.latitude), \(location.longitude)) with radius: \(radius) meters")

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = "Coffee"
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.landmark])
        request.region = MKCoordinateRegion(center: location, latitudinalMeters: radius, longitudinalMeters: radius)

        let search = MKLocalSearch(request: request)
        search.start { [weak self] response, error in
            if let error = error {
                print("Error fetching POIs: \(error.localizedDescription)")
                self?.locationError = error.localizedDescription
                return
            }

            guard let response = response, !response.mapItems.isEmpty else {
                print("No POIs found within a \(radius)-meter radius.")
                self?.locationError = "No landmarks found nearby within a \(radius)-meter radius."
                return
            }
            
            print("Found \(response.mapItems.count) POIs within a \(radius)-meter radius.")
            self?.pointsOfInterest = response.mapItems
        }
    }

}

extension CLLocationCoordinate2D {
    func distance(to other: CLLocationCoordinate2D) -> CLLocationDistance {
        let from = CLLocation(latitude: self.latitude, longitude: self.longitude)
        let to = CLLocation(latitude: other.latitude, longitude: other.longitude)
        return from.distance(from: to)
    }
}
