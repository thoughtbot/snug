import AppKit

/// Dispatches every URL the app receives: Meet URLs open in-app, everything
/// else forwards to the fallback browser. Serves both default-browser mode
/// and direct handoff (`open -a Meet <url>`, Velja, Finicky).
@MainActor
final class URLRouter {
    static let shared = URLRouter()

    /// Registered by the home window (SwiftUI's openWindow action); the
    /// action stays valid after the registering window closes.
    var openMeetingWindow: ((URL) -> Void)?

    /// Also registered by the home window, for the launch-to-open-a-meeting
    /// case: see `AppDelegate.applicationDidFinishLaunching`.
    var dismissHomeWindow: (() -> Void)?

    /// Whether an incoming URL has opened a meeting window this session.
    private(set) var didOpenMeetingWindow = false

    /// SwiftUI opens a home window of its own whenever the app is activated to
    /// follow a link, and nobody asked for it. It usually appears just *before*
    /// the routing that caused it, in which case `dismissHomeWindow` closes it;
    /// this covers the other order, where it turns up just afterwards and
    /// consumes the flag as it appears. Expires so a stale flag can't close a
    /// window opened later on purpose.
    private var suppressLandingUntil: Date?

    func consumeLandingSuppression() -> Bool {
        guard let deadline = suppressLandingUntil, Date() < deadline else { return false }
        suppressLandingUntil = nil
        return true
    }

    func route(_ url: URL) {
        switch MeetURLClassifier.classify(url) {
        case .meet(let meetURL):
            if let openMeetingWindow {
                suppressLandingUntil = Date().addingTimeInterval(3)
                openMeetingWindow(MeetURLClassifier.windowValue(for: meetURL))
                // The home window is the launcher: following a link replaces
                // it rather than leaving it open behind the meeting.
                dismissHomeWindow?()
                didOpenMeetingWindow = true
                NSApp.activate()
            } else {
                NSLog("no meeting-window opener registered; dropping \(meetURL)")
            }
        case .other(let otherURL):
            // Forwards never create windows or activate us; focus follows
            // the fallback browser.
            FallbackBrowser.forward(otherURL)
        }
    }
}
