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

    func route(_ url: URL) {
        switch MeetURLClassifier.classify(url) {
        case .meet(let meetURL):
            if let openMeetingWindow {
                openMeetingWindow(MeetURLClassifier.windowValue(for: meetURL))
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
