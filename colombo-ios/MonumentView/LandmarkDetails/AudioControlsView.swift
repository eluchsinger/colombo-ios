//
//  AudioControlsView.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 29.10.2024.
//

import SwiftUI


struct AudioControlsView: View {
    @ObservedObject var audioPlayer: AudioPlayer
    @State private var isEditingSlider = false
    
    private let speedOptions: [(label: String, value: Double)] = [
        ("0.75x", 0.75),
        ("1x", 1.0),
        ("1.25x", 1.25),
        ("1.5x", 1.5)
    ]
    
    var body: some View {
        VStack(spacing: 8) {
            // Time slider and labels
            VStack(spacing: 4) {
                Slider(
                    value: Binding(
                        get: { audioPlayer.currentTime },
                        set: { audioPlayer.seek(to: $0) }
                    ),
                    in: 0...max(audioPlayer.duration, 0.01),
                    onEditingChanged: { editing in
                        isEditingSlider = editing
                    }
                )
                .disabled(audioPlayer.duration == 0)
                
                HStack {
                    Text(formatTime(audioPlayer.currentTime))
                        .font(.caption)
                        .monospacedDigit()
                    Spacer()
                    Text(formatTime(audioPlayer.duration))
                        .font(.caption)
                        .monospacedDigit()
                }
                .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                // Play/Pause button
                Button(action: {
                    if audioPlayer.isPlaying {
                        audioPlayer.pause()
                    } else {
                        audioPlayer.resume()
                    }
                }) {
                    Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.blue)
                }
                
                // Playback speed selector
                Picker("Speed", selection: Binding(
                    get: { audioPlayer.playbackRate },
                    set: { audioPlayer.setPlaybackRate($0) }
                )) {
                    ForEach(speedOptions, id: \.value) { option in
                        Text(option.label)
                            .tag(option.value)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }
    
    private func formatTime(_ timeInSeconds: Double) -> String {
        let minutes = Int(timeInSeconds) / 60
        let seconds = Int(timeInSeconds) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
