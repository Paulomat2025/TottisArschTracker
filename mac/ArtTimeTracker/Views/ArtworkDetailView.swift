import SwiftUI
import UniformTypeIdentifiers

struct ArtworkDetailView: View {
    @EnvironmentObject var store: ArtworkStore
    let artwork: Artwork
    var onBack: () -> Void

    @State private var sessions: [TrackingSession] = []
    @State private var selectedSessionId: TrackingSession.ID?
    @State private var showMerge = false
    @State private var mergeTarget: Artwork?
    @State private var showRelink = false
    @State private var relinkFileName = ""

    private var currentArtwork: Artwork? {
        store.artworks.first(where: { $0.id == artwork.id })
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Button("← Zurück") { onBack() }
                Text(artwork.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                Text(currentArtwork?.formattedTotalTime ?? "0s")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                Spacer()
                Button("Zusammenführen") { showMerge.toggle() }
                Button("Archivieren", role: .destructive) {
                    store.archiveArtwork(id: artwork.id)
                    onBack()
                }
            }

            // Verknüpfte Datei (wie InDesign Links-Panel)
            GroupBox("Verknüpfte Datei") {
                HStack {
                    if let linked = currentArtwork?.linkedFileName {
                        Image(systemName: "link")
                            .foregroundStyle(.green)
                        Text("\(linked).clip")
                            .font(.system(.body, design: .monospaced))
                    } else {
                        Image(systemName: "link.badge.plus")
                            .foregroundStyle(.secondary)
                        Text("Keine Datei verknüpft")
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Datei wählen...") {
                        pickClipFile()
                    }
                    Button("Manuell verknüpfen") {
                        relinkFileName = currentArtwork?.linkedFileName ?? ""
                        showRelink = true
                    }
                    if currentArtwork?.linkedFileName != nil {
                        Button("Verknüpfung lösen") {
                            store.relinkArtwork(id: artwork.id, linkedFileName: nil)
                        }
                    }
                }
            }

            // Relink Sheet
            if showRelink {
                GroupBox("Datei manuell verknüpfen") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Gib den Dateinamen ein (ohne .clip Extension).")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        HStack {
                            TextField("Dateiname", text: $relinkFileName)
                                .textFieldStyle(.roundedBorder)
                            Text(".clip")
                                .foregroundStyle(.secondary)
                        }
                        HStack {
                            Button("Verknüpfen") {
                                let name = relinkFileName.trimmingCharacters(in: .whitespaces)
                                store.relinkArtwork(id: artwork.id, linkedFileName: name.isEmpty ? nil : name)
                                showRelink = false
                            }
                            Button("Abbrechen") { showRelink = false }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Merge
            if showMerge {
                GroupBox("Anderes Kunstwerk hierhin zusammenführen") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Alle Sessions werden übernommen, das andere Kunstwerk wird gelöscht.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Picker("Kunstwerk wählen:", selection: $mergeTarget) {
                            Text("Bitte wählen...").tag(nil as Artwork?)
                            ForEach(store.artworks.filter { $0.id != artwork.id }) { a in
                                Text("\(a.name) (\(a.sessions.count) Sessions)").tag(a as Artwork?)
                            }
                        }
                        HStack {
                            Button("Zusammenführen") {
                                if let target = mergeTarget {
                                    store.mergeArtworks(targetId: artwork.id, sourceId: target.id)
                                    showMerge = false
                                    mergeTarget = nil
                                    loadSessions()
                                }
                            }
                            .disabled(mergeTarget == nil)
                            Button("Abbrechen") { showMerge = false }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            // Sessions Table
            Table(sessions, selection: $selectedSessionId) {
                TableColumn("Datum") { s in Text(s.formattedDate) }
                TableColumn("Start") { s in Text(s.formattedStart) }
                TableColumn("Ende") { s in Text(s.formattedEnd) }
                TableColumn("Dauer") { s in Text(s.formattedDuration).fontWeight(.medium) }
            }

            HStack {
                Button("Ausgewählte Session löschen", role: .destructive) {
                    if let id = selectedSessionId {
                        store.deleteSession(id: id)
                        selectedSessionId = nil
                        loadSessions()
                    }
                }
                .disabled(selectedSessionId == nil)
            }
        }
        .padding()
        .onAppear { loadSessions() }
    }

    private func loadSessions() {
        sessions = Database.shared.getSessions(forArtwork: artwork.id)
    }

    private func pickClipFile() {
        let panel = NSOpenPanel()
        panel.title = "Clip Studio Paint Datei wählen"
        panel.allowedContentTypes = [UTType(filenameExtension: "clip") ?? .data]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false

        if panel.runModal() == .OK, let url = panel.url {
            let fileName = url.deletingPathExtension().lastPathComponent
            store.relinkArtwork(id: artwork.id, linkedFileName: fileName)
        }
    }
}
