import MapKit
import SwiftUI

struct MonumentView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLandmark: LandmarkItem?
    @State private var isLoggingOut = false
    @State private var logoutError: String?
    @State private var visitResponse: PlaceVisitResponse? {
        didSet {
            print("Visit response changed: \(visitResponse != nil)")
        }
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
                trailing: logoutButton
            )
            .sheet(item: $selectedLandmark) { landmark in
                ModernLandmarkDetailView(
                    landmark: landmark,
                    visitResponse: $visitResponse
                )
            }
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

    private var logoutButton: some View {
        Button(action: {
            performLogout()
        }) {
            if isLoggingOut {
                ProgressView()
                    .tint(.red)
            } else {
                Text("Log out")
                    .foregroundColor(.red)
            }
        }
        .disabled(isLoggingOut)
        .alert(
            "Logout Error",
            isPresented: .init(
                get: { logoutError != nil },
                set: { _ in logoutError = nil }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            if let error = logoutError {
                Text(error)
            }
        }
    }

    private func performLogout() {
        isLoggingOut = true

        Task {
            do {
                try await supabase.auth.signOut()

                await MainActor.run {
                    isLoggingOut = false
                    isLoggedIn = false
                }
            } catch {
                await MainActor.run {
                    isLoggingOut = false
                    logoutError = error.localizedDescription
                }
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
            Text(
                "Please allow access to your location to find nearby landmarks"
            )
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
            // Stop any playing audio before refreshing
            if let currentLandmark = locationManager.nearbyLandmarks.first {
                // This will trigger the onDisappear in PrimaryLandmarkView
                locationManager.nearbyLandmarks = []
            }
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
        VStack(spacing: 24) {
            if let primaryLandmark = locationManager.nearbyLandmarks.first {
                PrimaryLandmarkViewContainer(
                    landmark: primaryLandmark,
                    visitResponse: $visitResponse,
                    onPlayTapped: {
                        print(
                            "Play tapped for \(primaryLandmark.mapItem.name ?? "Unknown")"
                        )
                    },
                    onTap: {
                        selectedLandmark = primaryLandmark
                    }
                )
                .padding(.horizontal)

                if locationManager.nearbyLandmarks.count > 1,
                    let secondaryLandmark = locationManager.nearbyLandmarks[
                        safe: 1]
                {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next closest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        SecondaryLandmarkView(
                            landmark: secondaryLandmark,
                            onTap: {
                                selectedLandmark = secondaryLandmark
                            }
                        )
                    }
                }
            }

            Spacer()
        }
        .padding(.top)
    }

}

struct SecondaryLandmarkView: View {
    let landmark: LandmarkItem
    let onTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(landmark.mapItem.name ?? "Unknown Landmark")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                if let distance = landmark.mapItem.placemark.location?.distance(
                    from: CLLocation(
                        latitude: landmark.mapItem.placemark.coordinate
                            .latitude,
                        longitude: landmark.mapItem.placemark.coordinate
                            .longitude
                    ))
                {
                    Text(String(format: "%.0f meters away", distance))
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
}

// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}
