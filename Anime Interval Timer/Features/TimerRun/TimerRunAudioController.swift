import AVFoundation

/// Plays bundled music and SFX for `TimerRunViewController` phases.
final class TimerRunAudioController {

    private let store = SoundSettingsStore.shared
    private var musicPlayer: AVAudioPlayer?
    private var sfxPlayer: AVAudioPlayer?
    private var sfxStopWorkItem: DispatchWorkItem?
    private var studyTrackNames: [String] = ["study-sound1", "study-sound2", "study-sound3", "study-sound4"]
    private var lastStudyPick: String?

    func activateSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    func deactivateSession() {
        stopAll()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func stopAll() {
        sfxStopWorkItem?.cancel()
        sfxStopWorkItem = nil
        musicPlayer?.stop()
        musicPlayer = nil
        currentLoopingResource = nil
        sfxPlayer?.stop()
        sfxPlayer = nil
    }

    func stopMusicOnly() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentLoopingResource = nil
    }

    func refreshVolumes() {
        musicPlayer?.volume = store.musicVolume
        sfxPlayer?.volume = store.counterSFXVolume
    }

    /// Starts when start phase hits 4s left; clip capped at 4s playback.
    func playStartCounterTick() {
        playOneShotSFX(
            named: "3scounter",
            ext: "mp3",
            subdirectory: "Resources/Sounds/SFX",
            maxPlaybackDuration: 4
        )
    }

    /// Transition chime (only first 3s of asset).
    func playTransitionSuccess() {
        playOneShotSFX(
            named: "succes-sound",
            ext: "m4a",
            subdirectory: "Resources/Sounds/SFX",
            maxPlaybackDuration: 3
        )
    }

    /// Starts or switches looping music for the current phase.
    func syncMusic(phase: TimerPhase, timerKind: TimerKind) {
        switch phase {
        case .start:
            stopMusicOnly()
        case .focus:
            if timerKind == .study {
                let name = randomStudyTrack()
                playLoopingMusic(named: name, ext: "m4a", subdirectory: "Resources/Sounds/Music")
            } else {
                stopMusicOnly()
            }
        case .break_:
            playLoopingMusic(named: "break-sound", ext: "m4a", subdirectory: "Resources/Sounds/Music")
        }
    }

    private func randomStudyTrack() -> String {
        var pool = studyTrackNames
        if pool.count > 1, let last = lastStudyPick {
            pool.removeAll { $0 == last }
        }
        let pick = pool.randomElement() ?? studyTrackNames[0]
        lastStudyPick = pick
        return pick
    }

    private func bundleURL(named name: String, ext: String, subdirectory: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: ext, subdirectory: subdirectory)
            ?? Bundle.main.url(forResource: name, withExtension: ext)
    }

    private var currentLoopingResource: String?

    private func playLoopingMusic(named name: String, ext: String, subdirectory: String) {
        guard let url = bundleURL(named: name, ext: ext, subdirectory: subdirectory) else { return }
        let key = "\(name).\(ext)"
        if currentLoopingResource == key, musicPlayer?.isPlaying == true {
            musicPlayer?.volume = store.musicVolume
            return
        }
        currentLoopingResource = key
        musicPlayer?.stop()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.numberOfLoops = -1
            p.volume = store.musicVolume
            p.prepareToPlay()
            p.play()
            musicPlayer = p
        } catch {
            musicPlayer = nil
        }
    }

    private func playOneShotSFX(
        named name: String,
        ext: String,
        subdirectory: String,
        maxPlaybackDuration: TimeInterval? = nil
    ) {
        guard let url = bundleURL(named: name, ext: ext, subdirectory: subdirectory) else { return }
        sfxStopWorkItem?.cancel()
        sfxStopWorkItem = nil
        sfxPlayer?.stop()
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = store.counterSFXVolume
            p.prepareToPlay()
            p.play()
            sfxPlayer = p
            if let cap = maxPlaybackDuration, cap > 0 {
                let playerRef = p
                let work = DispatchWorkItem { [weak self] in
                    guard let self else { return }
                    guard self.sfxPlayer === playerRef else { return }
                    playerRef.stop()
                    if self.sfxPlayer === playerRef {
                        self.sfxPlayer = nil
                    }
                }
                sfxStopWorkItem = work
                DispatchQueue.main.asyncAfter(deadline: .now() + cap, execute: work)
            }
        } catch {
            sfxPlayer = nil
        }
    }
}
