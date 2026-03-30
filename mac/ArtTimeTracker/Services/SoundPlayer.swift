import AppKit

class SoundPlayer {
    static let shared = SoundPlayer()
    private var fartSound: NSSound?

    private init() {
        if let url = Bundle.module.url(forResource: "fart-sound", withExtension: "wav") {
            fartSound = NSSound(contentsOf: url, byReference: true)
        }
    }

    func playFart() {
        fartSound?.stop()
        fartSound?.play()
    }
}
