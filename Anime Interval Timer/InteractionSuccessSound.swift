import AVFoundation
import UIKit

/// `succes-sound` excerpt: 2nd & 3rd seconds only (from 1.0s to 3.0s in the file). Uses counter/SFX volume.
enum InteractionSuccessSound {

    private static var player: AVAudioPlayer?
    private static var stopWorkItem: DispatchWorkItem?

    static func playSuccesSecondAndThirdSeconds() {
        stopWorkItem?.cancel()
        stopWorkItem = nil
        player?.stop()
        let url = Bundle.main.url(forResource: "succes-sound", withExtension: "m4a", subdirectory: "Resources/Sounds/SFX")
            ?? Bundle.main.url(forResource: "succes-sound", withExtension: "m4a")
        guard let url else { return }
        do {
            let p = try AVAudioPlayer(contentsOf: url)
            p.volume = SoundSettingsStore.shared.counterSFXVolume
            p.currentTime = 1.0
            p.prepareToPlay()
            p.play()
            player = p
            let ref = p
            let work = DispatchWorkItem {
                guard player === ref else { return }
                ref.stop()
                if player === ref { player = nil }
            }
            stopWorkItem = work
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0, execute: work)
        } catch {
            player = nil
        }
    }
}
