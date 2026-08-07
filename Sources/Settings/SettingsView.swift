import AppKit
import SwiftUI

struct SettingsView: View {
    @State private var browsers: [URL] = []
    @State private var selection: URL = FallbackBrowser.appURL
    @State private var defaultBrowserMessage: String?

    @State private var hideSelfView = Preferences.hideSelfView
    @State private var autoJoin = Preferences.autoJoin

    var body: some View {
        Form {
            Toggle("Hide my video tile once others join", isOn: $hideSelfView)
                .onChange(of: hideSelfView) { _, newValue in
                    Preferences.hideSelfView = newValue
                }
            Text("Your camera stays on for others; only your own preview is hidden. Applies from the next time someone joins.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Toggle("Join meetings automatically", isOn: $autoJoin)
                .onChange(of: autoJoin) { _, newValue in
                    Preferences.autoJoin = newValue
                }
            Text("Skips Meet's \"Ready to join?\" screen. You won't get a chance to check your camera and microphone first.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Divider()

            Picker("Open non-Meet links in:", selection: $selection) {
                ForEach(browsers, id: \.self) { url in
                    Text(displayName(for: url)).tag(url)
                }
            }
            .onChange(of: selection) { _, newValue in
                FallbackBrowser.setAppURL(newValue)
            }

            LabeledContent("Default browser:") {
                VStack(alignment: .leading, spacing: 4) {
                    Button("Use Snug for All Links…") { makeDefaultBrowser() }
                    Text("Snug opens meeting links itself and sends everything else to the browser above.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let defaultBrowserMessage {
                        Text(defaultBrowserMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .padding(20)
        .frame(width: 460)
        .onAppear {
            browsers = FallbackBrowser.candidates()
            let current = FallbackBrowser.appURL
            if !browsers.contains(current) {
                browsers.append(current)
            }
            selection = current
        }
    }

    private func displayName(for url: URL) -> String {
        FileManager.default.displayName(atPath: url.path)
    }

    /// Both schemes: claiming only `http` leaves every https link — which is
    /// nearly all of them, meeting links included — with the old browser.
    private func makeDefaultBrowser() {
        Task {
            do {
                for scheme in ["http", "https"] {
                    try await NSWorkspace.shared.setDefaultApplication(
                        at: Bundle.main.bundleURL,
                        toOpenURLsWithScheme: scheme
                    )
                }
                defaultBrowserMessage = "Snug is now the default browser."
            } catch {
                defaultBrowserMessage = "Not changed: \(error.localizedDescription)"
            }
        }
    }
}
