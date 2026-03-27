import Foundation

/// Persisted volumes for timer session audio (music vs counter / SFX).
final class SoundSettingsStore {

    static let shared = SoundSettingsStore()

    private enum Keys {
        static let musicVolume = "soundSettings.musicVolume"
        static let counterSFXVolume = "soundSettings.counterSFXVolume"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if defaults.object(forKey: Keys.musicVolume) == nil {
            defaults.set(0.7, forKey: Keys.musicVolume)
        }
        if defaults.object(forKey: Keys.counterSFXVolume) == nil {
            defaults.set(0.85, forKey: Keys.counterSFXVolume)
        }
    }

    /// Background music (break, study focus tracks). 0...1
    var musicVolume: Float {
        get { clamp01(defaults.float(forKey: Keys.musicVolume)) }
        set { defaults.set(clamp01(newValue), forKey: Keys.musicVolume) }
    }

    /// 3-second counter + transition success SFX. 0...1
    var counterSFXVolume: Float {
        get { clamp01(defaults.float(forKey: Keys.counterSFXVolume)) }
        set { defaults.set(clamp01(newValue), forKey: Keys.counterSFXVolume) }
    }

    private func clamp01(_ v: Float) -> Float {
        min(1, max(0, v))
    }
}
