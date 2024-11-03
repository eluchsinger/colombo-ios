import CoreLocation
import Foundation
import MapKit
import SwiftUI

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    private let wikipediaManager = WikipediaLocationManager()
    private var lastFetchTime: Date?
    private let fetchInterval: TimeInterval = 1  // Reduced from 5 to 1 second
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
        locationManager.activityType = .fitness  // Changed from .otherNavigation for better updates
        locationManager.distanceFilter = 5  // Changed from 10000 to 5 meters

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
                self.locationError =
                    "Location access denied. Please enable it in Settings."
                self.stopUpdatingLocation()
            case .notDetermined:
                // Wait for user response to permission request
                break
            @unknown default:
                self.locationError = "Unknown location authorization status"
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
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

                // Reduced distance threshold from 10 to 5 meters
                if currentLoc.distance(from: latestLocation) > 5 {
                    self?.location = latestLocation.coordinate
                    self?.fetchLandmarksWithThrottle()
                }
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager, didFailWithError error: Error
    ) {
        DispatchQueue.main.async { [weak self] in
            if let clError = error as? CLError {
                switch clError.code {
                case .denied:
                    self?.locationError =
                        "Location access denied. Please check your settings."
                case .locationUnknown:
                    self?.locationError =
                        "Unable to determine location. Please try again."
                case .network:
                    self?.locationError =
                        "Network error. Please check your connection."
                default:
                    self?.locationError =
                        "Location error: \(clError.localizedDescription)"
                }
            } else {
                self?.locationError =
                    "Location error: \(error.localizedDescription)"
            }

            print("Location error: \(error.localizedDescription)")
        }
    }

    private func fetchLandmarksWithThrottle() {
        let now = Date()
        if let lastFetchTime = lastFetchTime,
            now.timeIntervalSince(lastFetchTime) < fetchInterval
        {
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

        let request = MKLocalPointsOfInterestRequest(
            center: userLocation, radius: searchRadius)
        request.pointOfInterestFilter = MKPointOfInterestFilter(including: [
            .landmark
        ])

        let search = MKLocalSearch(request: request)

        search.start { [weak self] response, error in
            guard let self = self else { return }
            
            Task {
                await self.processSearchResults(response: response, error: error, userLocation: userLocation)
            }
        }
    }
    
    private func processSearchResults(response: MKLocalSearch.Response?, error: Error?, userLocation: CLLocationCoordinate2D) async {
        if let error = error {
            await MainActor.run {
                self.isSearching = false
                self.locationError = "Search error: \(error.localizedDescription)"
                self.nearbyLandmarks = []
            }
            return
        }

        guard let searchResponse = response else {
            await MainActor.run {
                self.isSearching = false
                self.locationError = "No landmarks found nearby"
                self.nearbyLandmarks = []
            }
            return
        }
        
        await MainActor.run {
            self.isSearching = false
        }
        
        let userLoc = CLLocation(
            latitude: userLocation.latitude,
            longitude: userLocation.longitude
        )

        let nearbyItems = searchResponse.mapItems
            .filter { mapItem in
                guard let itemLocation = mapItem.placemark.location else { return false }
                return itemLocation.distance(from: userLoc) <= self.searchRadius
            }
            .sorted { item1, item2 in
                guard let loc1 = item1.placemark.location,
                      let loc2 = item2.placemark.location else { return false }
                return loc1.distance(from: userLoc) < loc2.distance(from: userLoc)
            }
        
        // Filter landmarks that have Wikipedia articles
        var landmarksWithArticles: [LandmarkItem] = []
        
        for mapItem in nearbyItems {
            guard let itemLocation = mapItem.placemark.location else { continue }
            
            do {
                let articles = try await self.wikipediaManager.fetchNearbyArticles(
                    coordinate: itemLocation.coordinate,
                    radius: 10,  // Convert Double to Int
                    limit: 1      // We only need one article per POI
                )
                
                if !articles.isEmpty {
                    print("Found Wikipedia article for \(mapItem.name ?? "unknown"):")
                    articles.forEach { article in
                        print("- Title: \(article.title)")
                        print("  Distance: \(String(format: "%.2f", article.dist))m")
                        print("  Page ID: \(article.pageid)")
                        print("  Coordinates: (\(article.lat), \(article.lon))")
                    }
                    
                    await MainActor.run {
                        landmarksWithArticles.append(LandmarkItem(mapItem: mapItem))
                    }
                } else {
                    print("No Wikipedia articles found for \(mapItem.name ?? "unknown")")
                }
            } catch {
                print("Error fetching Wikipedia articles for \(mapItem.name ?? "unknown"): \(error)")
                continue
            }
        }
        
        await MainActor.run {
            self.nearbyLandmarks = landmarksWithArticles
            if landmarksWithArticles.isEmpty {
                self.locationError = "No landmarks with Wikipedia articles found within \(Int(self.searchRadius)) meters"
            } else {
                self.locationError = nil
            }
        }
    }

    func refreshLandmarks() {
        nearbyLandmarks = []
        fetchNearbyLandmarks()
    }
}
