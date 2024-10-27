import SwiftUI
import MapKit

struct MonumentView: View {
    @Binding var isLoggedIn: Bool
    @StateObject private var locationManager = LocationManager()
    @State private var selectedLandmark: LandmarkItem?  // Changed type
    
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
                ModernLandmarkDetailView(landmark: landmark.mapItem)
            }
            .onAppear {
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
    
    // Update the landmarkListView in MonumentView
    private var landmarkListView: some View {
        VStack(spacing: 24) {
            if let primaryLandmark = locationManager.nearbyLandmarks.first {
                PrimaryLandmarkView(
                    landmark: primaryLandmark.mapItem,
                    onPlayTapped: {
                        print("Play tapped for \(primaryLandmark.mapItem.name ?? "Unknown")")
                        // Add your play functionality here
                    },
                    onTap: {
                        selectedLandmark = primaryLandmark
                    }
                )
                .padding(.horizontal)
                
                if locationManager.nearbyLandmarks.count > 1,
                   let secondaryLandmark = locationManager.nearbyLandmarks[safe: 1] {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Next closest")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        SecondaryLandmarkView(
                            landmark: secondaryLandmark.mapItem,
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
    
    private var logoutButton: some View {
        Button(action: {
            isLoggedIn = false
        }) {
            Text("Log out")
                .foregroundColor(.red)
        }
    }
}

struct PrimaryLandmarkView: View {
    let landmark: MKMapItem
    let onPlayTapped: () -> Void
    let onTap: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(landmark.name ?? "Unknown Landmark")
                        .font(.title2)
                        .bold()
                    
                    if let subtitle = formatAddress(from: landmark.placemark) {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                Button(action: onPlayTapped) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
            
            if let distance = landmark.placemark.location?.distance(from: CLLocation(
                latitude: landmark.placemark.coordinate.latitude,
                longitude: landmark.placemark.coordinate.longitude
            )) {
                Text(String(format: "%.0f meters away", distance))
                    .font(.headline)
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
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

struct SecondaryLandmarkView: View {
    let landmark: MKMapItem
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(landmark.name ?? "Unknown Landmark")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                if let distance = landmark.placemark.location?.distance(from: CLLocation(
                    latitude: landmark.placemark.coordinate.latitude,
                    longitude: landmark.placemark.coordinate.longitude
                )) {
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


@available(iOS 17.0, *)
struct ModernLandmarkDetailView: View {
    let landmark: MKMapItem
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    
    init(landmark: MKMapItem) {
        self.landmark = landmark
        self._cameraPosition = State(initialValue: .region(MKCoordinateRegion(
            center: landmark.placemark.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.001, longitudeDelta: 0.001)
        )))
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Modern Map implementation
                    Map(position: $cameraPosition) {
                        Annotation(
                            landmark.name ?? "Location",
                            coordinate: landmark.placemark.coordinate,
                            anchor: .bottom
                        ) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.title)
                                .foregroundColor(.red)
                                .background(Color.white.clipShape(Circle()))
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic))
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                    }
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
            placemark.subThoroughfare,
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


// Helper extension for safe array access
extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    MonumentView(isLoggedIn: .constant(true))
}

