import Foundation
import AppKit

@MainActor
class UpdateChecker {
    static let currentVersion = "1.0.0"

    static func checkForUpdate() {
        Task {
            guard let update = await fetchLatestRelease() else { return }

            let alert = NSAlert()
            alert.messageText = "Update verfügbar"
            alert.informativeText = "Version \(update.version) ist verfügbar!\n\nJetzt herunterladen?"
            alert.alertStyle = .informational
            alert.addButton(withTitle: "Herunterladen")
            alert.addButton(withTitle: "Später")

            if alert.runModal() == .alertFirstButtonReturn {
                if let url = URL(string: update.downloadUrl) {
                    NSWorkspace.shared.open(url)
                }
            }
        }
    }

    private static func fetchLatestRelease() async -> (version: String, downloadUrl: String)? {
        guard let url = URL(string: "https://api.github.com/repos/Paulomat2025/TottisArschTracker/releases/latest") else { return nil }

        var request = URLRequest(url: url)
        request.setValue("TottisArschTracker", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let tagName = json["tag_name"] as? String else { return nil }

        let version = tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName

        guard version.compare(currentVersion, options: .numeric) == .orderedDescending else { return nil }

        let releaseUrl = json["html_url"] as? String ?? ""

        var downloadUrl = releaseUrl
        if let assets = json["assets"] as? [[String: Any]] {
            for asset in assets {
                let name = asset["name"] as? String ?? ""
                if name.lowercased().contains("macos") && name.hasSuffix(".dmg") {
                    downloadUrl = asset["browser_download_url"] as? String ?? releaseUrl
                    break
                }
            }
        }

        return (version, downloadUrl)
    }
}
