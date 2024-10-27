import SwiftUI
import MapKit

// Extension to make MKMapItem identifiable
extension MKMapItem: Identifiable {
    public var id: String {
        // Create a unique identifier using the placemark's coordinates and name
        "\(placemark.coordinate.latitude),\(placemark.coordinate.longitude):\(name ?? "")"
    }
}

struct MonumentView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLandmark: MKMapItem?
    
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
                LandmarkDetailView(landmark: landmark)
            }
            .onAppear {
                // Only start updating if we have permission
                if locationManager.authorizationStatus == .authorizedWhenInUse ||
                   locationManager.authorizationStatus == .authorizedAlways {
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
        .disabled(locationManager.isSearching ||
                  locationManager.authorizationStatus != .authorizedWhenInUse)
    }
    
    private var locationStatusView: some View {
        Group {
            if let location = locationManager.location {
                VStack(spacing: 4) {
                    Text("Searching within 10 meters of your location")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("(\(location.latitude.formatted(.number.precision(.fractionLength(4)))), \(location.longitude.formatted(.number.precision(.fractionLength(4)))))")
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
        List {
            ForEach(locationManager.nearbyLandmarks, id: \.id) { landmark in
                LandmarkRowView(landmark: landmark)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLandmark = landmark
                    }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private var logoutButton: some View {
        Button(action: {
            isLoggedIn = false
        }) {
            Text("Log out")
                .foregroundColor(.red)
        }
    }
}

struct LandmarkRowView: View {
    let landmark: MKMapItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(landmark.name ?? "Unknown Landmark")
                .font(.headline)
            
            if let subtitle = formatAddress(from: landmark.placemark) {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            if let distance = landmark.placemark.location?.distance(from: CLLocation(
                latitude: landmark.placemark.coordinate.latitude,
                longitude: landmark.placemark.coordinate.longitude
            )) {
                Text(String(format: "%.0f meters away", distance))
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func formatAddress(from placemark: MKPlacemark) -> String? {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}

struct LandmarkDetailView: View {
    let landmark: MKMapItem
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Map snapshot
                    Map(coordinateRegion: .constant(MKCoordinateRegion(
                        center: landmark.placemark.coordinate,
                        span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
                    )))
                    .frame(height: 200)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 12) {
                        // Name and basic info
                        Text(landmark.name ?? "Unknown Landmark")
                            .font(.title2)
                            .bold()
                        
                        if let address = formatDetailedAddress(from: landmark.placemark) {
                            Label(address, systemImage: "location.fill")
                                .font(.subheadline)
                        }
                        
                        if let phoneNumber = landmark.phoneNumber {
                            Label(phoneNumber, systemImage: "phone.fill")
                                .font(.subheadline)
                        }
                        
                        if let url = landmark.url {
                            Link(destination: url) {
                                Label("Visit Website", systemImage: "globe")
                                    .font(.subheadline)
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Actions
                    VStack(spacing: 12) {
                        Button(action: {
                            openInMaps()
                        }) {
                            Label("Open in Maps", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        if let url = landmark.url {
                            ShareLink(item: url) {
                                Label("Share Location", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { dismiss() })
        }
    }
    
    private func formatDetailedAddress(from placemark: MKPlacemark) -> String? {
        let components = [
            placemark.subThoroughfare,  // Changed from streetNumber
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country
        ].compactMap { $0 }
        
        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
    
    private func openInMaps() {
        let mapItem = MKMapItem(placemark: landmark.placemark)
        mapItem.openInMaps()
    }
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}
