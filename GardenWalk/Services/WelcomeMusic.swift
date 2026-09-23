import AVFoundation
import SwiftUI

/// Plays the five GardenWalk pieces one at a time. Each song finishes, the world stays quiet
/// for a short while, then another piece begins. A full pass plays every track once before any repeats.
@MainActor
final class WelcomeMusic: NSObject, AVAudioPlayerDelegate {
    static let tracks = ["GardenEvening", "MossPath", "Tinbrook", "OrchardDusk", "Deepwood"]
    /// Quiet between songs. Shorter than Minecraft's overworld wait, because these pieces are brief.
    private static let gapRange = 7.0...14.0
    private static let playingVolume: Float = 0.32

    private var player: AVAudioPlayer?
    private var queue: [String] = []
    private var lastPlayed: String?
    private var phase: Phase = .idle
    private var pausedMidTrack = false
    private var wantsPlayback = false
    private var gapTask: Task<Void, Never>?
    private var fadeTask: Task<Void, Never>?

    private enum Phase {
        case idle
        case playing
        case betweenTracks
    }

    func play() {
        guard phase == .idle else { return }
        wantsPlayback = true
        if pausedMidTrack, let player {
            pausedMidTrack = false
            resume(player)
        } else {
            beginNextTrack()
        }
    }

    func pause() {
        wantsPlayback = false
        gapTask?.cancel()
        gapTask = nil
        fadeTask?.cancel()
        fadeTask = nil
        if phase == .playing {
            pausedMidTrack = true
            player?.pause()
            player?.volume = 0
        } else {
            pausedMidTrack = false
        }
        phase = .idle
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func handleInterruption(_ notification: Notification, shouldResume: Bool) {
        guard let raw = notification.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt,
              let type = AVAudioSession.InterruptionType(rawValue: raw) else { return }
        if type == .began {
            fadeTask?.cancel()
            player?.pause()
            if phase == .playing {
                pausedMidTrack = true
                phase = .idle
            }
        } else if shouldResume,
                  let rawOptions = notification.userInfo?[AVAudioSessionInterruptionOptionKey] as? UInt,
                  AVAudioSession.InterruptionOptions(rawValue: rawOptions).contains(.shouldResume) {
            play()
        }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.trackFinished(player)
        }
    }

    private func beginNextTrack(skipped: Int = 0) {
        guard wantsPlayback, skipped < Self.tracks.count else { return }
        let name = dequeueTrack()
        guard let url = Self.url(for: name) else {
            beginNextTrack(skipped: skipped + 1)
            return
        }
        do {
            try configureSession()
            let audio = try AVAudioPlayer(contentsOf: url)
            audio.delegate = self
            audio.numberOfLoops = 0
            audio.volume = 0
            audio.prepareToPlay()
            player?.delegate = nil
            player = audio
            pausedMidTrack = false
            phase = .playing
            audio.play()
            audio.setVolume(Self.playingVolume, fadeDuration: 1.6)
            scheduleFadeOut(for: audio)
        } catch {
            beginNextTrack(skipped: skipped + 1)
        }
    }

    private func resume(_ audio: AVAudioPlayer) {
        do {
            try configureSession()
        } catch {
            return
        }
        phase = .playing
        audio.play()
        audio.setVolume(Self.playingVolume, fadeDuration: 1.2)
        scheduleFadeOut(for: audio)
    }

    private func trackFinished(_ finished: AVAudioPlayer) {
        guard finished === player, wantsPlayback, phase == .playing else { return }
        phase = .betweenTracks
        fadeTask?.cancel()
        let gap = Double.random(in: Self.gapRange)
        gapTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: UInt64(gap * 1_000_000_000))
            guard !Task.isCancelled, self.wantsPlayback else { return }
            self.gapTask = nil
            self.phase = .idle
            self.beginNextTrack()
        }
    }

    private func scheduleFadeOut(for audio: AVAudioPlayer) {
        fadeTask?.cancel()
        let lead = 2.2
        let wait = max(0, audio.duration - audio.currentTime - lead)
        fadeTask = Task { @MainActor in
            if wait > 0 {
                try? await Task.sleep(nanoseconds: UInt64(wait * 1_000_000_000))
            }
            guard !Task.isCancelled, self.wantsPlayback, self.player === audio, self.phase == .playing else { return }
            audio.setVolume(0, fadeDuration: lead)
        }
    }

    private func dequeueTrack() -> String {
        if queue.isEmpty {
            var bag = Self.tracks.shuffled()
            if bag.count > 1, bag[0] == lastPlayed {
                bag.swapAt(0, 1)
            }
            queue = bag
        }
        let name = queue.removeFirst()
        lastPlayed = name
        return name
    }

    private static func url(for name: String) -> URL? {
        for ext in ["m4a", "wav"] {
            if let url = Bundle.main.url(forResource: name, withExtension: ext, subdirectory: nil) {
                return url
            }
        }
        return nil
    }

    private func configureSession() throws {
        // Respect the silent switch and any music already playing on the phone.
        try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try AVAudioSession.sharedInstance().setActive(true)
    }
}

/// Keeps the soundtrack playing for the whole app session, including after login.
struct WelcomeMusicHost: View {
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("gardenwalk.welcome.music") private var musicEnabled = true
    @State private var music = WelcomeMusic()

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .onAppear { updateMusic() }
            .onChange(of: musicEnabled) { _, _ in updateMusic() }
            .onChange(of: scenePhase) { _, _ in updateMusic() }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.interruptionNotification)) { notification in
                music.handleInterruption(notification, shouldResume: musicEnabled && scenePhase == .active)
            }
            .onReceive(NotificationCenter.default.publisher(for: AVAudioSession.routeChangeNotification)) { notification in
                if let raw = notification.userInfo?[AVAudioSessionRouteChangeReasonKey] as? UInt,
                   AVAudioSession.RouteChangeReason(rawValue: raw) == .oldDeviceUnavailable {
                    musicEnabled = false
                }
            }
    }

    private func updateMusic() {
        if musicEnabled && scenePhase == .active {
            music.play()
        } else {
            music.pause()
        }
    }
}
