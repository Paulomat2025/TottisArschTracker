import AppKit

class SoundPlayer {
    static let shared = SoundPlayer()
    private var fartSound: NSSound?

    private init() {
        if let url = Bundle.module.url(forResource: "love-sound", withExtension: "wav") {
            fartSound = NSSound(contentsOf: url, byReference: true)
        }
    }

    func playFart() {
        fartSound?.stop()
        fartSound?.play()
    }

    func startGlobalMonitor() {
        // Fart bei jedem Tastendruck (Text-Input)
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            self.playFart()
            return event
        }
    }
}
