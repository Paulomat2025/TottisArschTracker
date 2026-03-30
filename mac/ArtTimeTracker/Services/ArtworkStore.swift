import Foundation

@MainActor
class ArtworkStore: ObservableObject {
    @Published var artworks: [Artwork] = []
    @Published var recentSessions: [(session: TrackingSession, artworkName: String)] = []

    private let db = Database.shared

    init() { reload() }

    func reload() {
        artworks = db.getArtworks()
        recentSessions = db.getRecentSessions()
    }

    func getOrCreateByFileName(_ name: String) -> Artwork {
        let artwork = db.getOrCreateByFileName(name)
        reload()
        return artwork
    }

    func addArtwork(name: String, linkedFileName: String? = nil) {
        db.addArtwork(name: name, linkedFileName: linkedFileName)
        reload()
    }

    func relinkArtwork(id: Int, linkedFileName: String?) {
        db.relinkArtwork(id: id, linkedFileName: linkedFileName)
        reload()
    }

    func addSession(_ session: (artworkId: Int, start: Date, end: Date)) {
        db.addSession(artworkId: session.artworkId, start: session.start, end: session.end)
        reload()
    }

    func deleteSession(id: Int) {
        db.deleteSession(id: id)
        reload()
    }

    func archiveArtwork(id: Int) {
        db.archiveArtwork(id: id)
        reload()
    }

    func mergeArtworks(targetId: Int, sourceId: Int) {
        db.mergeArtworks(targetId: targetId, sourceId: sourceId)
        reload()
    }
}
