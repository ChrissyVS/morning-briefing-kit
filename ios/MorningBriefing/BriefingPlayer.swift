import AVFoundation
import MediaPlayer
import Observation
import UIKit

/// Plays the briefing with full controls: in the app, on the Lock Screen and in Control Center.
@MainActor
@Observable
final class BriefingPlayer {
    static let shared = BriefingPlayer()

    private(set) var episode: Episode?
    private(set) var isPlaying = false
    private(set) var isLoading = false
    private(set) var currentTime: Double = 0
    private(set) var duration: Double = 0
    var errorMessage: String?
    var rate: Float = Float(UserDefaults.standard.double(forKey: "rate")).nonZero(or: 1.0) {
        didSet {
            UserDefaults.standard.set(Double(rate), forKey: "rate")
            player?.defaultRate = rate
            if isPlaying { player?.rate = rate }
            updateNowPlaying()
        }
    }

    @ObservationIgnored private var player: AVPlayer?
    @ObservationIgnored private var timeObserver: Any?
    @ObservationIgnored private var endObserver: NSObjectProtocol?

    private init() {
        setUpRemoteCommands()
        episode = BriefingSource.newestSaved()
    }

    // MARK: - Playback

    /// Fetches today's briefing (if it's new) and starts playing.
    func playLatest() async throws {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let latest = try await BriefingSource.latest()
            if latest != episode || player == nil {
                await load(latest)
            }
            play()
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }

    func play() {
        guard let player else { return }
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio)
        try? session.setActive(true)
        if duration > 0, currentTime >= duration - 1 { seek(to: 0) }
        player.defaultRate = rate
        player.play()
        isPlaying = true
        updateNowPlaying()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlaying()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if player != nil {
            play()
        } else {
            Task { try? await playLatest() }
        }
    }

    func skip(by seconds: Double) {
        seek(to: min(max(currentTime + seconds, 0), duration))
    }

    func seek(to seconds: Double) {
        currentTime = seconds
        player?.seek(to: CMTime(seconds: seconds, preferredTimescale: 600))
        updateNowPlaying()
    }

    private func load(_ newEpisode: Episode) async {
        if let timeObserver { player?.removeTimeObserver(timeObserver) }
        if let endObserver { NotificationCenter.default.removeObserver(endObserver) }

        let asset = AVURLAsset(url: newEpisode.audioURL)
        duration = (try? await asset.load(.duration).seconds) ?? 0
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        player = newPlayer
        episode = newEpisode
        currentTime = 0

        timeObserver = newPlayer.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: 600), queue: .main
        ) { [weak self] time in
            MainActor.assumeIsolated { self?.currentTime = time.seconds }
        }
        endObserver = NotificationCenter.default.addObserver(
            forName: AVPlayerItem.didPlayToEndTimeNotification, object: item, queue: .main
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.isPlaying = false
                self?.updateNowPlaying()
            }
        }
    }

    // MARK: - Lock Screen and Control Center

    private func setUpRemoteCommands() {
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.play() }
            return .success
        }
        center.pauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.pause() }
            return .success
        }
        center.togglePlayPauseCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.togglePlayPause() }
            return .success
        }
        center.skipForwardCommand.preferredIntervals = [15]
        center.skipForwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.skip(by: 15) }
            return .success
        }
        center.skipBackwardCommand.preferredIntervals = [15]
        center.skipBackwardCommand.addTarget { [weak self] _ in
            MainActor.assumeIsolated { self?.skip(by: -15) }
            return .success
        }
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            MainActor.assumeIsolated { self?.seek(to: event.positionTime) }
            return .success
        }
    }

    private func updateNowPlaying() {
        guard let episode else { return }
        var info: [String: Any] = [
            MPMediaItemPropertyTitle: "Morning Briefing",
            MPMediaItemPropertyArtist: episode.title,
            MPMediaItemPropertyPlaybackDuration: duration,
            MPNowPlayingInfoPropertyElapsedPlaybackTime: currentTime,
            MPNowPlayingInfoPropertyPlaybackRate: isPlaying ? Double(rate) : 0.0,
            MPNowPlayingInfoPropertyDefaultPlaybackRate: Double(rate),
        ]
        if let cover = UIImage(named: "Cover") {
            info[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(boundsSize: cover.size) { _ in cover }
        }
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }
}

private extension Float {
    func nonZero(or fallback: Float) -> Float { self == 0 ? fallback : self }
}
