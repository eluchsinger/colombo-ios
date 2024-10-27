import Foundation
import CoreLocation
import MapKit
import SwiftUI


// Wrapper struct for MKMapItem

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private var lastFetchTime: Date?
    private let fetchInterval: TimeInterval = 5
    private let searchRadius: CLLocationDistance = 50
    
    @Published var location: CLLocationCoordinate2D? = nil
    @Published var locationError: String? = nil
    @Published var nearbyLandmarks: [LandmarkItem] = []
    @Published var isSearching: Bool = false
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .otherNavigation
        locationManager.distanceFilter = 10
        
        // Just store the current status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startUpdatingLocation() {
        // Don't check location services here
        // Just start updates - the delegate will handle any issues
        locationManager.startUpdatingLocation()
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // Handle authorization status changes
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            self.authorizationStatus = manager.authorizationStatus
            
            switch manager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                self.startUpdatingLocation()
            case .denied, .restricted:
                self.locationError = "Location access denied. Please enable it in Settings."
                self.stopUpdatingLocation()
            case .notDetermined:
                // Wait for user response to permission request
                break
            @unknown default:
                self.locationError = "Unknown location authorization status"
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latestLocation = locations.last else {
            locationError = "Unable to determine location"
            return
        }
        
        DispatchQueue.main.async { [weak self] in
            // Clear any existing location errors since we got a valid location
            self?.locationError = nil
            
            // Compare distances using CLLocation
            if self?.location == nil {
                self?.location = latestLocation.coordinate
                self?.fetchLandmarksWithThrottle()
            } else if let currentLocation = self?.location {
                let currentLoc = CLLocation(
                    latitude: currentLocation.latitude,
                    longitude: currentLocation.longitude
                )
                
                if currentLoc.distance(from: latestLocation) > 10 {
                    self?.location = latestLocation.coordinate
                    self?.fetchLandmarksWithThrottle()
                }
            }
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async { [weak self] in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self?.locationError = "Location access denied. Please check your settings."
                case .locationUnknown:
                    self?.locationError = "Unable to determine location. Please try again."
                case .network:
                    self?.locationError = "Network error. Please check your connection."
                default:
                    self?.locationError = "Location error: \(clError.localizedDescription)"
                }
            } else {
                self?.locationError = "Location error: \(error.localizedDescription)"
            }
            
            print("Location error: \(error.localizedDescription)")
        }
    }
    
    private func fetchLandmarksWithThrottle() {
        let now = Date()
        if let lastFetchTime = lastFetchTime,
           now.timeIntervalSince(lastFetchTime) < fetchInterval {
            return
        }
        lastFetchTime = now
        fetchNearbyLandmarks()
    }
    
    private func fetchNearbyLandmarks() {
        guard let userLocation = location else {
            locationError = "No location available"
            return
        }
        
        isSearching = true
        
        let request = MKLocalPointsOfInterestRequest(center: userLocation, radius: searchRadius)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [.landmark])
        
        let search = MKLocalSearch(request: request)
        
        search.start { [weak self] response, error in
            DispatchQueue.main.async {
                self?.isSearching = false
                
                if let error = error {
                    self?.locationError = "Search error: \(error.localizedDescription)"
                    self?.nearbyLandmarks = []
                    return
                }
                
                guard let response = response else {
                    self?.locationError = "No landmarks found nearby"
                    self?.nearbyLandmarks = []
                    return
                }
                
                guard let userCoordinate = self?.location else { return }
                let userLoc = CLLocation(
                    latitude: userCoordinate.latitude,
                    longitude: userCoordinate.longitude
                )
                
                let nearbyItems = response.mapItems
                    .filter { mapItem in
                        guard let itemLocation = mapItem.placemark.location else { return false }
                        return itemLocation.distance(from: userLoc) <= (self?.searchRadius ?? 50)
                    }
                    .sorted { item1, item2 in
                        guard let loc1 = item1.placemark.location,
                              let loc2 = item2.placemark.location else { return false }
                        return loc1.distance(from: userLoc) < loc2.distance(from: userLoc)
                    }
                    .map { LandmarkItem(mapItem: $0) }  // Convert to LandmarkItem
                
                self?.nearbyLandmarks = nearbyItems
                if nearbyItems.isEmpty {
                    self?.locationError = "No landmarks found within \(Int(self?.searchRadius ?? 50)) meters"
                } else {
                    self?.locationError = nil
                }
                
                print("Found \(nearbyItems.count) landmarks within range")
            }
        }
    }
    
    func refreshLandmarks() {
        fetchNearbyLandmarks()
    }
}
