import MapKit
import SwiftUI

struct MonumentView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLandmark: LandmarkItem?

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
            .onAppear {
                if locationManager.authorizationStatus == .authorizedWhenInUse
                    || locationManager.authorizationStatus == .authorizedAlways
                {
                    locationManager.startUpdatingLocation()
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
            locationManager.refreshLandmarks()
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
        List(locationManager.nearbyLandmarks) { landmark in
            NavigationLink(destination: ModernLandmarkDetailView(
                landmark: landmark,
                visitResponse: .constant(nil)
            )) {
                LandmarkRowView(landmark: landmark)
            }
        }
    }
}

struct LandmarkRowView: View {
    let landmark: LandmarkItem

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(landmark.mapItem.name ?? "Unknown Landmark")
                    .font(.headline)

                if let distance = landmark.mapItem.placemark.location?.distance(
                    from: CLLocation(
                        latitude: landmark.mapItem.placemark.coordinate.latitude,
                        longitude: landmark.mapItem.placemark.coordinate.longitude
                    ))
                {
                    Text(String(format: "%.0f meters away", distance))
                        .font(.subheadline)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}
