import Foundation
import AVFoundation

class AudioPlayer: NSObject, ObservableObject {
    private var player: AVAudioPlayer?
    @Published var isPlaying = false
    @Published var isLoading = false
    var onPlaybackFinished: (() -> Void)?
    
    override init() {
        super.init()
    }
    
    func play(from urlString: String) async throws {
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        guard let url = URL(string: urlString) else {
            throw NSError(domain: "AudioPlayer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }
        
        // Download the audio file
        let (audioData, _) = try await URLSession.shared.data(from: url)
        
        // Initialize and play the audio on the main thread
        try await MainActor.run {
            player = try AVAudioPlayer(data: audioData)
            player?.delegate = self
            player?.play()
            isPlaying = true
        }
    }
    
    func stop() {
        player?.stop()
        isPlaying = false
        onPlaybackFinished?()
    }
}

extension AudioPlayer: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async { [weak self] in
            self?.isPlaying = false
            self?.onPlaybackFinished?()
        }
    }
}
