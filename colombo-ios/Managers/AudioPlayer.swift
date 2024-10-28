import AVFoundation

enum AudioPlayerError: Error {
    case invalidURL
    case failedToLoadAsset
    
    var localizedDescription: String {
        switch self {
        case .invalidURL:
            return "Invalid audio URL"
        case .failedToLoadAsset:
            return "Failed to load audio"
        }
    }
}

class AudioPlayer: ObservableObject {
    private var audioPlayer: AVPlayer?
    private var timeObserver: Any?

    @Published var isPlaying = false
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var playbackRate: Double = 1.0

    var onPlaybackFinished: (() -> Void)?

    func play(from urlString: String) async throws {
        guard let url = URL(string: urlString) else {
            throw AudioPlayerError.invalidURL
        }

        let asset = AVURLAsset(url: url)

        do {
            let duration = try await asset.load(.duration)

            await MainActor.run {
                self.duration = duration.seconds
                self.currentTime = 0

                let playerItem = AVPlayerItem(asset: asset)
                self.audioPlayer = AVPlayer(playerItem: playerItem)

                // Add time observer
                self.timeObserver = self.audioPlayer?.addPeriodicTimeObserver(
                    forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                    queue: .main
                ) { [weak self] time in
                    self?.currentTime = time.seconds
                }

                // Add completion observer
                NotificationCenter.default.addObserver(
                    forName: .AVPlayerItemDidPlayToEndTime,
                    object: playerItem,
                    queue: .main
                ) { [weak self] _ in
                    self?.isPlaying = false
                    self?.currentTime = 0
                    self?.onPlaybackFinished?()
                }

                self.audioPlayer?.play()
                self.isPlaying = true
            }
        } catch {
            throw AudioPlayerError.failedToLoadAsset
        }
    }

    func stop() {
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
        isPlaying = false
        currentTime = 0
        onPlaybackFinished?()
    }

    func pause() {
        audioPlayer?.pause()
        isPlaying = false
    }

    func resume() {
        audioPlayer?.play()
        isPlaying = true
    }

    func seek(to time: Double) {
        audioPlayer?.seek(to: CMTime(seconds: time, preferredTimescale: 600))
    }

    func setPlaybackRate(_ rate: Double) {
        audioPlayer?.rate = Float(rate)
        playbackRate = rate
    }

    deinit {
        if let timeObserver = timeObserver {
            audioPlayer?.removeTimeObserver(timeObserver)
        }
    }
}
