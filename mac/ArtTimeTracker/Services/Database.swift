import Foundation
import SQLite3

class Database {
    static let shared = Database()
    private var db: OpaquePointer?

    private init() {
        let folder = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            .appendingPathComponent("ArtTimeTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let path = folder.appendingPathComponent("arttimetracker.db").path

        if sqlite3_open(path, &db) != SQLITE_OK {
            print("Failed to open database")
            return
        }
        createTables()
    }

    private func createTables() {
        execute("""
            CREATE TABLE IF NOT EXISTS Artworks (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                Name TEXT NOT NULL,
                Description TEXT,
                CreatedAt TEXT NOT NULL,
                IsArchived INTEGER NOT NULL DEFAULT 0,
                LinkedFileName TEXT
            )
        """)
        execute("""
            CREATE TABLE IF NOT EXISTS Sessions (
                Id INTEGER PRIMARY KEY AUTOINCREMENT,
                ArtworkId INTEGER NOT NULL,
                StartTime TEXT NOT NULL,
                EndTime TEXT NOT NULL,
                FOREIGN KEY (ArtworkId) REFERENCES Artworks(Id) ON DELETE CASCADE
            )
        """)
        // Migration: add LinkedFileName if missing
        execute("ALTER TABLE Artworks ADD COLUMN LinkedFileName TEXT")
    }

    private func execute(_ sql: String) {
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    private static let iso: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    // MARK: - Artworks

    func getArtworks(includeArchived: Bool = false) -> [Artwork] {
        let sql = includeArchived
            ? "SELECT Id, Name, Description, CreatedAt, IsArchived, LinkedFileName FROM Artworks ORDER BY CreatedAt DESC"
            : "SELECT Id, Name, Description, CreatedAt, IsArchived, LinkedFileName FROM Artworks WHERE IsArchived = 0 ORDER BY CreatedAt DESC"

        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        defer { sqlite3_finalize(stmt) }

        var artworks: [Artwork] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let id = Int(sqlite3_column_int(stmt, 0))
            let name = String(cString: sqlite3_column_text(stmt, 1))
            let desc = sqlite3_column_text(stmt, 2).map { String(cString: $0) }
            let created = Self.iso.date(from: String(cString: sqlite3_column_text(stmt, 3))) ?? Date()
            let archived = sqlite3_column_int(stmt, 4) != 0
            let linked = sqlite3_column_text(stmt, 5).map { String(cString: $0) }
            let sessions = getSessions(forArtwork: id)
            artworks.append(Artwork(id: id, name: name, description: desc, createdAt: created,
                                    isArchived: archived, linkedFileName: linked, sessions: sessions))
        }
        return artworks
    }

    /// Sucht per LinkedFileName, dann per Name, oder legt neu an.
    func getOrCreateByFileName(_ fileName: String) -> Artwork {
        // 1. Suche nach LinkedFileName
        if let found = getArtworks().first(where: { $0.linkedFileName == fileName }) {
            return found
        }
        // 2. Fallback: Name-Match + auto-link
        if let found = getArtworks().first(where: { $0.name == fileName }) {
            relinkArtwork(id: found.id, linkedFileName: fileName)
            return found
        }
        // 3. Neu anlegen
        return addArtwork(name: fileName, linkedFileName: fileName)
    }

    @discardableResult
    func addArtwork(name: String, linkedFileName: String? = nil) -> Artwork {
        let sql = "INSERT INTO Artworks (Name, LinkedFileName, CreatedAt, IsArchived) VALUES (?, ?, ?, 0)"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_text(stmt, 1, (name as NSString).utf8String, -1, nil)
        if let linked = linkedFileName {
            sqlite3_bind_text(stmt, 2, (linked as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, 2)
        }
        sqlite3_bind_text(stmt, 3, (Self.iso.string(from: Date()) as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        let id = Int(sqlite3_last_insert_rowid(db))
        return Artwork(id: id, name: name, description: nil, createdAt: Date(),
                       isArchived: false, linkedFileName: linkedFileName, sessions: [])
    }

    func relinkArtwork(id: Int, linkedFileName: String?) {
        let sql = "UPDATE Artworks SET LinkedFileName = ? WHERE Id = ?"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        if let linked = linkedFileName {
            sqlite3_bind_text(stmt, 1, (linked as NSString).utf8String, -1, nil)
        } else {
            sqlite3_bind_null(stmt, 1)
        }
        sqlite3_bind_int(stmt, 2, Int32(id))
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
    }

    func archiveArtwork(id: Int) {
        execute("UPDATE Artworks SET IsArchived = 1 WHERE Id = \(id)")
    }

    func mergeArtworks(targetId: Int, sourceId: Int) {
        execute("UPDATE Sessions SET ArtworkId = \(targetId) WHERE ArtworkId = \(sourceId)")
        execute("DELETE FROM Artworks WHERE Id = \(sourceId)")
    }

    // MARK: - Sessions

    func getSessions(forArtwork artworkId: Int) -> [TrackingSession] {
        let sql = "SELECT Id, ArtworkId, StartTime, EndTime FROM Sessions WHERE ArtworkId = ? ORDER BY StartTime DESC"
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_int(stmt, 1, Int32(artworkId))
        defer { sqlite3_finalize(stmt) }

        var sessions: [TrackingSession] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            sessions.append(TrackingSession(
                id: Int(sqlite3_column_int(stmt, 0)),
                artworkId: Int(sqlite3_column_int(stmt, 1)),
                startTime: Self.iso.date(from: String(cString: sqlite3_column_text(stmt, 2))) ?? Date(),
                endTime: Self.iso.date(from: String(cString: sqlite3_column_text(stmt, 3))) ?? Date()
            ))
        }
        return sessions
    }

    func getRecentSessions(days: Int = 7) -> [(session: TrackingSession, artworkName: String)] {
        let sql = """
            SELECT s.Id, s.ArtworkId, s.StartTime, s.EndTime, a.Name
            FROM Sessions s JOIN Artworks a ON s.ArtworkId = a.Id
            WHERE s.StartTime >= ? ORDER BY s.StartTime DESC
        """
        let since = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        var stmt: OpaquePointer?
        guard sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK else { return [] }
        sqlite3_bind_text(stmt, 1, (Self.iso.string(from: since) as NSString).utf8String, -1, nil)
        defer { sqlite3_finalize(stmt) }

        var results: [(TrackingSession, String)] = []
        while sqlite3_step(stmt) == SQLITE_ROW {
            let s = TrackingSession(
                id: Int(sqlite3_column_int(stmt, 0)),
                artworkId: Int(sqlite3_column_int(stmt, 1)),
                startTime: Self.iso.date(from: String(cString: sqlite3_column_text(stmt, 2))) ?? Date(),
                endTime: Self.iso.date(from: String(cString: sqlite3_column_text(stmt, 3))) ?? Date()
            )
            results.append((s, String(cString: sqlite3_column_text(stmt, 4))))
        }
        return results
    }

    @discardableResult
    func addSession(artworkId: Int, start: Date, end: Date) -> TrackingSession {
        let sql = "INSERT INTO Sessions (ArtworkId, StartTime, EndTime) VALUES (?, ?, ?)"
        var stmt: OpaquePointer?
        sqlite3_prepare_v2(db, sql, -1, &stmt, nil)
        sqlite3_bind_int(stmt, 1, Int32(artworkId))
        sqlite3_bind_text(stmt, 2, (Self.iso.string(from: start) as NSString).utf8String, -1, nil)
        sqlite3_bind_text(stmt, 3, (Self.iso.string(from: end) as NSString).utf8String, -1, nil)
        sqlite3_step(stmt)
        sqlite3_finalize(stmt)
        return TrackingSession(id: Int(sqlite3_last_insert_rowid(db)), artworkId: artworkId, startTime: start, endTime: end)
    }

    func deleteSession(id: Int) {
        execute("DELETE FROM Sessions WHERE Id = \(id)")
    }
}
