import AppKit

/// The browser that receives every non-Meet URL when this app is the system
/// default browser.
@MainActor
enum FallbackBrowser {
    private static let defaultsKey = "fallbackBrowserPath"
    private static let probeURL = URL(string: "https://example.com/")!

    /// Safari is always present and can't be us, so it's the unset default.
    static var appURL: URL {
        if let path = UserDefaults.standard.string(forKey: defaultsKey) {
            let url = URL(fileURLWithPath: path)
            if url != Bundle.main.bundleURL, FileManager.default.fileExists(atPath: path) {
                return url
            }
        }
        return URL(fileURLWithPath: "/Applications/Safari.app")
    }

    static func setAppURL(_ url: URL) {
        UserDefaults.standard.set(url.path, forKey: defaultsKey)
    }

    /// Installed browsers, excluding ourselves (loop guard).
    static func candidates() -> [URL] {
        NSWorkspace.shared.urlsForApplications(toOpen: probeURL)
            .filter { $0.standardizedFileURL != Bundle.main.bundleURL.standardizedFileURL }
    }

    static func forward(_ url: URL) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        NSWorkspace.shared.open([url], withApplicationAt: appURL, configuration: configuration) { _, error in
            if let error {
                NSLog("forward to \(appURL.lastPathComponent) failed: \(error.localizedDescription)")
            }
        }
    }
}
