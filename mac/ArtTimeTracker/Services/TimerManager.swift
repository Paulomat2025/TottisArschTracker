import Foundation

@MainActor
class TimerManager: ObservableObject {
    @Published var isRunning = false
    @Published var currentArtwork: Artwork?
    @Published var elapsed: TimeInterval = 0

    private var startTime: Date?
    private var timer: Timer?

    var formattedElapsed: String {
        let h = Int(elapsed) / 3600
        let m = (Int(elapsed) % 3600) / 60
        let s = Int(elapsed) % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    func start(for artwork: Artwork) {
        if isRunning && currentArtwork?.id == artwork.id { return }
        let _ = stop()

        currentArtwork = artwork
        startTime = Date()
        isRunning = true
        elapsed = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self, let start = self.startTime else { return }
                self.elapsed = Date().timeIntervalSince(start)
            }
        }
    }

    func stop() -> (artworkId: Int, start: Date, end: Date)? {
        guard isRunning, let artwork = currentArtwork, let start = startTime else { return nil }

        timer?.invalidate()
        timer = nil

        let end = Date()
        isRunning = false
        currentArtwork = nil
        startTime = nil
        elapsed = 0

        guard end.timeIntervalSince(start) >= 5 else { return nil }
        return (artworkId: artwork.id, start: start, end: end)
    }
}
