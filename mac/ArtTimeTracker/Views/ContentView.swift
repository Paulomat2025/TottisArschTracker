import SwiftUI

enum NavigationTab {
    case dashboard, statistics
}

struct ContentView: View {
    @EnvironmentObject var store: ArtworkStore
    @EnvironmentObject var processWatcher: ProcessWatcher
    @EnvironmentObject var timerManager: TimerManager
    @State private var selectedTab: NavigationTab = .dashboard
    @State private var selectedArtwork: Artwork?

    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                Label("Dashboard", systemImage: "clock")
                    .tag(NavigationTab.dashboard)
                Label("Statistiken", systemImage: "chart.bar")
                    .tag(NavigationTab.statistics)
            }
            .navigationSplitViewColumnWidth(min: 150, ideal: 180)

            Spacer()

            // Status
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(processWatcher.isWatching ? .green : .red)
                        .frame(width: 8, height: 8)
                    Text("Auto-Tracking")
                        .font(.caption)
                }
                Text(processWatcher.statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
        } detail: {
            Group {
                if let artwork = selectedArtwork {
                    ArtworkDetailView(artwork: artwork, onBack: { selectedArtwork = nil })
                } else {
                    switch selectedTab {
                    case .dashboard:
                        DashboardView(onSelectArtwork: { selectedArtwork = $0 })
                    case .statistics:
                        StatisticsView()
                    }
                }
            }
        }
        .navigationTitle("💩 Tottis Arsch Tracker")
    }
}
