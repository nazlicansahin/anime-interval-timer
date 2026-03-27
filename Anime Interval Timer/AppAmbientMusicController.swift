import AVFoundation

/// Loops `study-sound4` on non–timer-run screens; pauses while `TimerRunViewController` is visible.
final class AppAmbientMusicController {

    static let shared = AppAmbientMusicController()

    private let store = SoundSettingsStore.shared
    private var player: AVAudioPlayer?
    private var timerRunDepth = 0

    func beginTimerRunSession() {
        timerRunDepth += 1
        if timerRunDepth == 1 {
            player?.stop()
            player = nil
        }
    }

    func endTimerRunSession() {
        timerRunDepth = max(0, timerRunDepth - 1)
        if timerRunDepth == 0 {
            startAmbientIfNeeded()
        }
    }

    /// Call from list, create, settings, home, onboarding when those screens appear.
    func ensureAmbientForNonTimerScreen() {
        guard timerRunDepth == 0 else { return }
        startAmbientIfNeeded()
    }

    func applyMusicVolumeFromSettings() {
        player?.volume = store.musicVolume
    }

    private func startAmbientIfNeeded() {
        guard timerRunDepth == 0 else { return }
        if player?.isPlaying == true {
            player?.volume = store.musicVolume
            return
        }
        let url = Bundle.main.url(forResource: "study-sound4", withExtension: "m4a", subdirectory: "Resources/Sounds/Music")
            ?? Bundle.main.url(forResource: "study-sound4", withExtension: "m4a")
        guard let url else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = store.musicVolume
            p.prepareToPlay()
            p.play()
            player = p
        } catch {
            player = nil
        }
    }
}
