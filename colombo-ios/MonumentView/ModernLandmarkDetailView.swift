//
//  ModernLandmarkDetailView.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 29.10.2024.
//

import MapKit
import SwiftUI

@available(iOS 17.0, *)
struct ModernLandmarkDetailView: View {
    let landmark: LandmarkItem
    @Binding var visitResponse: PlaceVisitResponse?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition

    init(landmark: LandmarkItem, visitResponse: Binding<PlaceVisitResponse?>) {
        self.landmark = landmark
        self._visitResponse = visitResponse  // Use _visitResponse for binding
        self._cameraPosition = State(
            initialValue: .region(
                MKCoordinateRegion(
                    center: landmark.mapItem.placemark.coordinate,
                    span: MKCoordinateSpan(
                        latitudeDelta: 0.001, longitudeDelta: 0.001)
                )))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
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
                .frame(height: 200)
                .cornerRadius(12)
                .padding(.horizontal)

                if let response = visitResponse {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("About this Place")
                            .font(.title2)
                            .bold()
                            .padding(.horizontal)

                        VStack(alignment: .leading, spacing: 8) {
                            if let subtitle = response.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Text(response.storyText)
                                .font(.body)
                        }
                        .padding(.horizontal)
                    }
                    Divider()
                        .padding(.vertical)
                }

                // Location info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location Details")
                        .font(.title2)
                        .bold()
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 8) {
                        if let address = formatDetailedAddress(
                            from: landmark.mapItem.placemark)
                        {
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
                    .padding(.horizontal)
                }

                // Actions
                VStack(spacing: 12) {
                    Button(action: {
                        openInMaps()
                    }) {
                        Label("Open in Maps", systemImage: "map.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    if let url = landmark.mapItem.url {
                        ShareLink(item: url) {
                            Label(
                                "Share Location",
                                systemImage: "square.and.arrow.up"
                            )
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(landmark.mapItem.name ?? "Location Details")
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
