//
//  PrimaryLandmarkView.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 28.10.2024.
//

import MapKit
import SwiftUI

struct PrimaryLandmarkViewContainer: View {
    let landmark: LandmarkItem
    @Binding var visitResponse: PlaceVisitResponse?
    let onPlayTapped: () -> Void
    let onTap: () -> Void

    var body: some View {
        PrimaryLandmarkView(
            landmark: landmark,
            visitResponse: $visitResponse,
            onPlayTapped: onPlayTapped,
            onTap: onTap
        )
    }
}
struct PrimaryLandmarkView: View {
    let landmark: LandmarkItem
    @Binding var visitResponse: PlaceVisitResponse?
    @StateObject private var audioPlayer = AudioPlayer()
    let onPlayTapped: () -> Void
    let onTap: () -> Void

    @State private var isLoading = false
    @State private var loadingState: LoadingState = .idle
    @State private var errorMessage: String?

    enum LoadingState {
        case idle
        case generatingStory
        case preparingAudio
        case playing

        var message: String {
            switch self {
            case .idle:
                return ""
            case .generatingStory:
                return "Generating story..."
            case .preparingAudio:
                return "Preparing audio..."
            case .playing:
                return "Playing"
            }
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(landmark.mapItem.name ?? "Unknown Landmark")
                        .font(.title2)
                        .bold()

                    if let subtitle = formatAddress(
                        from: landmark.mapItem.placemark)
                    {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    if loadingState != .idle {
                        HStack {
                            Text(loadingState.message)
                                .font(.caption)
                                .foregroundColor(.blue)
                            if loadingState != .playing {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                        }
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                }

                Spacer()

                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.stop()
                    } else {
                        Task {
                            await playAudio()
                        }
                    }
                }) {
                    Image(
                        systemName: audioPlayer.isPlaying
                            ? "stop.circle.fill" : "play.circle.fill"
                    )
                    .font(.system(size: 44))
                    .foregroundColor(isLoading ? .gray : .blue)
                    .opacity(isLoading ? 0.5 : 1)
                }
                .buttonStyle(.plain)
                .disabled(isLoading)
            }

            if let distance = landmark.mapItem.placemark.location?.distance(
                from: CLLocation(
                    latitude: landmark.mapItem.placemark.coordinate.latitude,
                    longitude: landmark.mapItem.placemark.coordinate.longitude
                ))
            {
                Text(String(format: "%.0f meters away", distance))
                    .font(.headline)
                    .foregroundColor(.blue)
            }

            // Audio controls (only show when audio is loaded)
            if loadingState == .playing || audioPlayer.duration > 0 {
                AudioControlsView(audioPlayer: audioPlayer)
                    .padding(.top, 8)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
        .shadow(radius: 2)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .onAppear {
            audioPlayer.onPlaybackFinished = {
                loadingState = .idle
            }
        }
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func playAudio() async {
            isLoading = true
            errorMessage = nil
            loadingState = .generatingStory
            
            do {
                let response = try await PlaceVisitService.shared.visitPlace(
                    landmark: landmark,
                    language: Locale.current.language.languageCode?.identifier
                )
                print("Got visit response: \(response)") // Add this
                visitResponse = response
                print("Set visit response: \(visitResponse != nil)") // Add this
                
                
                loadingState = .preparingAudio
                
                try await audioPlayer.play(from: response.audioUri)
                
                loadingState = .playing
                isLoading = false
            } catch {
                if let audioError = error as? AudioPlayerError {
                    errorMessage = audioError.localizedDescription
                } else if let placeError = error as? PlaceVisitError {
                    errorMessage = placeError.localizedDescription
                } else {
                    errorMessage = error.localizedDescription
                }
                loadingState = .idle
                isLoading = false
            }
        }

    private func formatAddress(from placemark: MKPlacemark) -> String? {
        let components = [
            placemark.thoroughfare,
            placemark.locality,
            placemark.administrativeArea,
            placemark.postalCode,
        ].compactMap { $0 }

        return components.isEmpty ? nil : components.joined(separator: ", ")
    }
}
