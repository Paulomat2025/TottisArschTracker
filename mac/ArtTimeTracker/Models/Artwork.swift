import Foundation
import SQLite3

struct Artwork: Identifiable, Hashable {
    let id: Int
    var name: String
    var description: String?
    var createdAt: Date
    var isArchived: Bool
    var linkedFileName: String?
    var sessions: [TrackingSession]

    var totalDuration: TimeInterval {
        sessions.reduce(0) { $0 + $1.duration }
    }

    var formattedTotalTime: String {
        Self.formatDuration(totalDuration)
    }

    static func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return "\(hours)h \(String(format: "%02d", minutes))m"
        } else if minutes > 0 {
            return "\(minutes)m \(String(format: "%02d", seconds))s"
        }
        return "\(seconds)s"
    }
}

struct TrackingSession: Identifiable, Hashable {
    let id: Int
    let artworkId: Int
    let startTime: Date
    let endTime: Date

    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var formattedDuration: String {
        Artwork.formatDuration(duration)
    }

    var formattedDate: String {
        let f = DateFormatter()
        f.dateFormat = "dd.MM.yyyy"
        return f.string(from: startTime)
    }

    var formattedStart: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: startTime)
    }

    var formattedEnd: String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: endTime)
    }
}
