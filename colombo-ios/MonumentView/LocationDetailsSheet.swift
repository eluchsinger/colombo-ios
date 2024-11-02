import SwiftUI
import MapKit

@available(iOS 17.0, *)
struct LocationDetailsSheet: View {
    let landmark: LandmarkItem
    @State private var cameraPosition: MapCameraPosition
    
    init(landmark: LandmarkItem) {
        self.landmark = landmark
        self._cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: landmark.mapItem.placemark.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.001, longitudeDelta: 0.001)
                )))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Map
                    Map(position: $cameraPosition) {
                        Annotation(
                            landmark.mapItem.name ?? "Location",
                            coordinate: landmark.mapItem.placemark.coordinate,
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
                    .frame(maxWidth: .infinity)
                    .frame(height: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal)

                    // Location info
                    GroupBox {
                        VStack(alignment: .leading, spacing: 16) {
                            if let address = formatDetailedAddress(from: landmark.mapItem.placemark) {
                                Label(address, systemImage: "location.fill")
                                    .font(.subheadline)
                            }

                            if let phoneNumber = landmark.mapItem.phoneNumber {
                                Label(phoneNumber, systemImage: "phone.fill")
                                    .font(.subheadline)
                            }

                            if let url = landmark.mapItem.url {
                                Link(destination: url) {
                                    Label("Visit Website", systemImage: "globe")
                                        .font(.subheadline)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    } label: {
                        Text("Location Details")
                            .font(.headline)
                    }
                    .padding(.horizontal)

                    // Actions
                    VStack(spacing: 12) {
                        Button(action: openInMaps) {
                            Label("Open in Maps", systemImage: "map.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }

                        if let url = landmark.mapItem.url {
                            ShareLink(item: url) {
                                Label("Share Location", systemImage: "square.and.arrow.up")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Location Information")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func formatDetailedAddress(from placemark: MKPlacemark) -> String? {
        let components = [
            placemark.subThoroughfare,
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
            placemark.country,
        ].compactMap { $0 }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }

    private func openInMaps() {
        let mapItem = MKMapItem(placemark: landmark.mapItem.placemark)
        mapItem.openInMaps()
    }
}
