//
//  colombo_iosApp.swift
//  colombo-ios
//
//  Created by Esteban Luchsinger on 27.10.2024.
//

import SwiftUI
import AVFoundation


@main
struct colombo_iosApp: App {
    
    init() {
        setupAudio()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
    
    private func setupAudio() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }
}
