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
    @State private var visitResponse: PlaceVisitResponse?
    @Environment(\.dismiss) private var dismiss
    @State private var cameraPosition: MapCameraPosition
    @State private var isLoading = false
    @State private var error: String?
    @State private var showingLocationDetails = false

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
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical)
                } else if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                } else if let response = visitResponse {
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
                                    .padding(.horizontal)
                            }
                            Text(response.storyText)
                                .font(.body)
                                .lineSpacing(4)
                                .padding(.horizontal)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    Text("No data available")
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .padding(.vertical)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(landmark.mapItem.name ?? "Location Details")
        .toolbar {
            Button {
                showingLocationDetails = true
            } label: {
                Image(systemName: "info.circle")
            }
        }
        .sheet(isPresented: $showingLocationDetails) {
            LocationDetailsSheet(landmark: landmark)
        }
        .task {
            await loadStory()
        }
    }

    private func loadStory() async {
        isLoading = true
        error = nil
        
        do {
            visitResponse = try await PlaceVisitService.shared.visitPlace(landmark: landmark)
            print("visitResponse set: \(String(describing: visitResponse))")
        } catch {
            if let placeError = error as? PlaceVisitError {
                self.error = placeError.localizedDescription
            } else {
                self.error = error.localizedDescription
            }
        }
        
        isLoading = false
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
