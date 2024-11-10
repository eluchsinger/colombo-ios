import MapKit
import SwiftUI

struct MonumentView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()
    @StateObject private var activityManager = LandmarkTrackingActivity()
    @State private var selectedLandmark: LandmarkItem?
    // Removed visitResponse as it's no longer needed

    private var closestLandmark: LandmarkItem? {
        locationManager.nearbyLandmarks.first
    }

    private var remainingLandmarks: [LandmarkItem] {
        Array(locationManager.nearbyLandmarks.dropFirst())
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                locationStatusView

                Divider()

                if locationManager.authorizationStatus == .notDetermined {
                    requestLocationView
                } else if locationManager.isSearching {
                    ProgressView("Searching for landmarks...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if locationManager.nearbyLandmarks.isEmpty {
                    emptyStateView
                } else {
                    landmarkListView
                }
            }
            .navigationTitle("Nearby Landmarks")
            .navigationBarItems(
                leading: refreshButton,
                trailing: NavigationLink(destination: UserSettingsView()) {
                    Image(systemName: "gear")
                }
            )
            .task {
                // Initialize location updates when view appears
                if locationManager.authorizationStatus == .authorizedWhenInUse
                    || locationManager.authorizationStatus == .authorizedAlways
                {
                    locationManager.startUpdatingLocation()
                    locationManager.refreshLandmarks()
                }
            }
            .onDisappear {
                locationManager.stopUpdatingLocation()
            }
        }
    }

    private var requestLocationView: some View {
        VStack(spacing: 16) {
            Image(systemName: "location.circle")
                .font(.system(size: 50))
                .foregroundColor(.blue)
            Text("Location Access Required")
                .font(.headline)
            Text("Please allow access to your location to find nearby landmarks")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Button("Allow Location Access") {
                locationManager.requestLocationPermission()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var refreshButton: some View {
        Button(action: {
            Task {
                locationManager.refreshLandmarks()
            }
        }) {
            Image(systemName: "arrow.clockwise")
        }
        .disabled(
            locationManager.isSearching
                || locationManager.authorizationStatus != .authorizedWhenInUse)
    }

    private var locationStatusView: some View {
        Group {
            if let location = locationManager.location {
                VStack(spacing: 4) {
                    Text("Searching within 10 meters of your location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(
                        "(\(location.latitude.formatted(.number.precision(.fractionLength(4)))), \(location.longitude.formatted(.number.precision(.fractionLength(4)))))"
                    )
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            } else if let error = locationManager.locationError {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundColor(.red)
                    .font(.subheadline)
            } else {
                ProgressView("Locating you...")
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "building.columns")
                .font(.system(size: 50))
                .foregroundColor(.secondary)
            Text("No Landmarks Nearby")
                .font(.headline)
            Text("There are no landmarks within 10 meters of your location")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var landmarkListView: some View {
        ScrollView {
            VStack(spacing: 16) {
                if let closest = closestLandmark {
                    NavigationLink(destination: ModernLandmarkDetailView(landmark: closest)) {
                        PrimaryLandmarkView(
                            landmark: closest,
                            userLocation: locationManager.location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.horizontal)
                    .onChange(of: locationManager.location?.latitude) { _, _ in
                        updateActivityForClosestLandmark(closest)
                    }
                    .onChange(of: locationManager.location?.longitude) { _, _ in
                        updateActivityForClosestLandmark(closest)
                    }
                    .onAppear {
                        activityManager.startTracking(
                            landmarkName: closest.mapItem.name ?? "Unknown Landmark"
                        )
                    }
                    .onDisappear {
                        activityManager.stopTracking()
                    }
                }

                if !remainingLandmarks.isEmpty {
                    ForEach(remainingLandmarks) { landmark in
                        NavigationLink(destination: ModernLandmarkDetailView(
                            landmark: landmark
                        )) {
                            LandmarkRowView(
                                landmark: landmark,
                                userLocation: locationManager.location.map { CLLocation(latitude: $0.latitude, longitude: $0.longitude) }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }
    
    private func updateActivityForClosestLandmark(_ landmark: LandmarkItem) {
        guard let location = locationManager.location,
              let landmarkLocation = landmark.mapItem.placemark.location else {
            return
        }
        
        let userLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distance = landmarkLocation.distance(from: userLocation)
        activityManager.updateActivity(
            landmarkName: landmark.mapItem.name ?? "Unknown Landmark",
            distance: distance
        )
    }
}

struct LandmarkRowView: View {
    let landmark: LandmarkItem
    let userLocation: CLLocation?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(landmark.mapItem.name ?? "Unknown Landmark")
                    .font(.headline)

                if let userLocation = userLocation,
                   let landmarkLocation = landmark.mapItem.placemark.location {
                    Text(String(format: "%.0f meters away", landmarkLocation.distance(from: userLocation)))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}
