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
    @StateObject private var audioPlayer = AudioPlayer()

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
            VStack(alignment: .leading, spacing: 24) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else if let error = error {
                    VStack(spacing: 8) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.red)
                        Text(error)
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(24)
                } else if let response = visitResponse {
                    Group {
                        // Title Section
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About this Place")
                                .font(.title)
                                .bold()
                            if let subtitle = response.subtitle {
                                Text(subtitle)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Audio Controls
                        AudioControlsView(audioPlayer: audioPlayer)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        // Story Text
                        Text(response.storyText)
                            .font(.body)
                            .lineSpacing(6)
                            .padding(.horizontal)
                    }
                } else {
                    ContentUnavailableView(
                        "No Data Available",
                        systemImage: "doc.text.fill",
                        description: Text("The content for this location could not be loaded.")
                    )
                    .padding()
                }
            }
            .padding(.vertical)
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
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func loadStory() async {
        isLoading = true
        error = nil
        
        do {
            visitResponse = try await PlaceVisitService.shared.visitPlace(landmark: landmark)
            if let audioUri = visitResponse?.audioUri {
                try await audioPlayer.play(from: audioUri)
            }
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
