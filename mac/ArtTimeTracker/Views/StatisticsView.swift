import SwiftUI
import Charts

struct StatisticsView: View {
    @EnvironmentObject var store: ArtworkStore
    @State private var dailyData: [DailyEntry] = []
    @State private var artworkData: [ArtworkEntry] = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Statistiken")
                    .font(.title2)
                    .fontWeight(.semibold)

                // Daily chart
                GroupBox("Zeit pro Tag (letzte 30 Tage)") {
                    Chart(dailyData) { entry in
                        BarMark(
                            x: .value("Tag", entry.date, unit: .day),
                            y: .value("Stunden", entry.hours)
                        )
                        .foregroundStyle(.blue.gradient)
                    }
                    .chartYAxisLabel("Stunden")
                    .frame(height: 250)
                    .padding(.vertical, 4)
                }

                // Artwork chart
                GroupBox("Stunden pro Kunstwerk") {
                    Chart(artworkData) { entry in
                        BarMark(
                            x: .value("Kunstwerk", entry.name),
                            y: .value("Stunden", entry.hours)
                        )
                        .foregroundStyle(.purple.gradient)
                    }
                    .chartYAxisLabel("Stunden")
                    .frame(height: 250)
                    .padding(.vertical, 4)
                }
            }
            .padding()
        }
        .onAppear { loadData() }
    }

    private func loadData() {
        let sessions = Database.shared.getRecentSessions(days: 30)

        // Daily
        var byDay: [Date: TimeInterval] = [:]
        for item in sessions {
            let day = Calendar.current.startOfDay(for: item.session.startTime)
            byDay[day, default: 0] += item.session.duration
        }
        let today = Calendar.current.startOfDay(for: Date())
        let start = Calendar.current.date(byAdding: .day, value: -30, to: today)!
        var d = start
        var daily: [DailyEntry] = []
        while d <= today {
            daily.append(DailyEntry(date: d, hours: (byDay[d] ?? 0) / 3600))
            d = Calendar.current.date(byAdding: .day, value: 1, to: d)!
        }
        dailyData = daily

        // By artwork
        var byArtwork: [String: TimeInterval] = [:]
        for item in sessions {
            byArtwork[item.artworkName, default: 0] += item.session.duration
        }
        artworkData = byArtwork
            .map { ArtworkEntry(name: $0.key, hours: $0.value / 3600) }
            .sorted { $0.hours > $1.hours }
    }
}

struct DailyEntry: Identifiable {
    let id = UUID()
    let date: Date
    let hours: Double
}

struct ArtworkEntry: Identifiable {
    let id = UUID()
    let name: String
    let hours: Double
}
