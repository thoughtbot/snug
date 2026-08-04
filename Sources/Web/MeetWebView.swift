import SwiftUI
import WebKit

/// Hosts a Meet `WebPage` in SwiftUI via the macOS 26 WebView.
struct MeetWebView: View {
    let page: WebPage
    @State private var assertion = PowerAssertion()

    var body: some View {
        WebView(page)
            .frame(minWidth: 900, minHeight: 620)
            .navigationTitle(displayTitle)
            .onAppear {
                if page.url == nil {
                    page.load(URLRequest(url: MeetPageFactory.homeURL))
                }
            }
            .onChange(of: page.cameraCaptureState) { updateAssertion() }
            .onChange(of: page.microphoneCaptureState) { updateAssertion() }
            .onDisappear { assertion.setActive(false) }
    }

    /// The page titles itself "Meet"/"Google Meet"; rebrand the window
    /// title while keeping the useful part (e.g. the meeting code).
    private var displayTitle: String {
        let title = page.title
            .replacingOccurrences(of: "Google Meet", with: "Snug")
            .replacingOccurrences(of: "Meet", with: "Snug")
            .trimmingCharacters(in: .whitespaces)
        return title.isEmpty ? "Snug" : title
    }

    /// In a call = camera or mic capturing (muted still counts).
    private func updateAssertion() {
        assertion.setActive(
            page.cameraCaptureState != .none || page.microphoneCaptureState != .none
        )
    }
}
