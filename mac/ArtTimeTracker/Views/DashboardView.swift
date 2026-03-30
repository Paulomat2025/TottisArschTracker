import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: ArtworkStore
    @EnvironmentObject var timerManager: TimerManager
    var onSelectArtwork: (Artwork) -> Void

    @State private var newArtworkName = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Timer
                GroupBox {
                    VStack(spacing: 12) {
                        if timerManager.isRunning, let name = timerManager.currentArtwork?.name {
                            Text("Tracking: \(name)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("Kein aktives Tracking")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(timerManager.formattedElapsed)
                            .font(.system(size: 48, weight: .ultraLight, design: .monospaced))

                        Text("Clip Studio Paint wird automatisch erkannt")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                // Neues Kunstwerk
                GroupBox("Neues Kunstwerk") {
                    HStack {
                        TextField("Name", text: $newArtworkName)
                            .textFieldStyle(.roundedBorder)
                        Button("Hinzufügen") {
                            guard !newArtworkName.trimmingCharacters(in: .whitespaces).isEmpty else { return }
                            store.addArtwork(name: newArtworkName.trimmingCharacters(in: .whitespaces))
                            newArtworkName = ""
                        }
                    }
                }

                // Kunstwerke
                Text("Kunstwerke")
                    .font(.headline)

                ForEach(store.artworks) { artwork in
                    Button {
                        onSelectArtwork(artwork)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(artwork.name)
                                    .foregroundStyle(.primary)
                                if let linked = artwork.linkedFileName {
                                    Text("📎 \(linked).clip")
                                        .font(.caption2)
                                        .foregroundStyle(.tertiary)
                                }
                            }
                            Spacer()
                            Text(artwork.formattedTotalTime)
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundStyle(.primary)
                            Text("\(artwork.sessions.count) Sessions")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)
                    Divider()
                }

                // Letzte Sessions
                Text("Letzte Sessions")
                    .font(.headline)
                    .padding(.top, 4)

                ForEach(store.recentSessions, id: \.session.id) { item in
                    HStack {
                        Text(item.artworkName)
                            .fontWeight(.medium)
                        Spacer()
                        Text(item.session.formattedDate + " " + item.session.formattedStart)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(item.session.formattedDuration)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                    .padding(.vertical, 2)
                    Divider()
                }
            }
            .padding()
        }
        .onAppear { store.reload() }
    }
}
