import Foundation
import AppKit

@MainActor
class ProcessWatcher: ObservableObject {
    @Published var currentFileName: String?
    @Published var isWatching = false
    @Published var statusText = "Warte auf Clip Studio Paint..."

    var onFileChanged: ((String?) -> Void)?

    private var timer: Timer?
    private var lastDetected: String?

    func start() {
        isWatching = true
        statusText = "Warte auf Clip Studio Paint..."
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.poll()
            }
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        isWatching = false
        if currentFileName != nil {
            currentFileName = nil
            lastDetected = nil
            onFileChanged?(nil)
        }
    }

    private func poll() {
        let fileName = detectOpenFile()

        guard fileName != lastDetected else { return }
        lastDetected = fileName
        currentFileName = fileName

        if let name = fileName {
            statusText = "Tracking: \(name)"
        } else {
            statusText = "Warte auf Clip Studio Paint..."
        }

        onFileChanged?(fileName)
    }

    private func detectOpenFile() -> String? {
        let apps = NSWorkspace.shared.runningApplications
        for app in apps {
            let bundleId = app.bundleIdentifier ?? ""
            let appName = app.localizedName ?? ""

            // Match verschiedene CSP-Varianten
            let isCSP = bundleId.lowercased().contains("clipstudio") ||
                         bundleId.lowercased().contains("clip-studio") ||
                         bundleId.lowercased().contains("celsys") ||
                         appName.contains("CLIP STUDIO") ||
                         appName.contains("CLIPStudio") ||
                         appName.contains("Clip Studio")

            guard isCSP else { continue }

            let pid = app.processIdentifier
            let options = CGWindowListOption(arrayLiteral: .optionOnScreenOnly, .excludeDesktopElements)
            guard let windowList = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { continue }

            for window in windowList {
                guard let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                      ownerPID == pid,
                      let title = window[kCGWindowName as String] as? String,
                      !title.isEmpty else { continue }
                if let parsed = parseFileName(title) {
                    return parsed
                }
            }
        }
        return nil
    }

    private func parseFileName(_ title: String) -> String? {
        let parts = title.components(separatedBy: " - ")
        for part in parts {
            var cleaned = part.trimmingCharacters(in: .whitespaces)
            cleaned = cleaned.replacingOccurrences(of: "[Geändert]", with: "")
            cleaned = cleaned.replacingOccurrences(of: "[Modified]", with: "")
            cleaned = cleaned.replacingOccurrences(of: "[Recovered]", with: "")
            cleaned = cleaned.replacingOccurrences(of: "*", with: "")
            cleaned = cleaned.trimmingCharacters(in: .whitespaces)

            if cleaned.lowercased().hasSuffix(".clip") {
                return (cleaned as NSString).deletingPathExtension
            }
        }
        return nil
    }
}
