import SwiftUI

@main
struct ArtTimeTrackerApp: App {
    @StateObject private var store = ArtworkStore()
    @StateObject private var processWatcher = ProcessWatcher()
    @StateObject private var timerManager = TimerManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(store)
                .environmentObject(processWatcher)
                .environmentObject(timerManager)
                .onAppear {
                    processWatcher.onFileChanged = { fileName in
                        Task { @MainActor in
                            if let name = fileName {
                                let artwork = store.getOrCreateByFileName(name)
                                timerManager.start(for: artwork)
                            } else {
                                if let session = timerManager.stop() {
                                    store.addSession(session)
                                }
                            }
                        }
                    }
                    processWatcher.start()
                    UpdateChecker.checkForUpdate()
                }
                .buttonStyle(FartButtonStyle())
                .frame(minWidth: 700, minHeight: 450)
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 900, height: 620)
    }
}
