import SwiftUI
import WebKit

/// Hosts a Meet `WebPage` in SwiftUI via the macOS 26 WebView.
struct MeetWebView: View {
    let page: WebPage
    let state: MeetPageState
    @State private var assertion = PowerAssertion()

    var body: some View {
        WebView(page)
            .frame(minWidth: 900, minHeight: 620)
            .navigationTitle(displayTitle)
            .focusedSceneValue(\.meetPage, focusedPage)
            .onAppear {
                if page.url == nil {
                    page.load(URLRequest(url: MeetPageFactory.homeURL))
                }
            }
            .onChange(of: page.cameraCaptureState) { updateAssertion() }
            .onChange(of: page.microphoneCaptureState) { updateAssertion() }
            .onDisappear { assertion.setActive(false) }
    }

    /// What menu commands act on. Reading the page's state here — in the body's
    /// dependency graph rather than inside the command — is what makes menu
    /// items re-enable when this window navigates into a call, and what keeps
    /// the Microphone checkmark in step with Meet.
    private var focusedPage: FocusedMeetPage {
        FocusedMeetPage(
            page: page,
            isInMeeting: MeetURLClassifier.isMeetingPage(page.url),
            isMicrophoneMuted: state.isMicrophoneMuted
        )
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
