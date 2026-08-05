import Foundation
import WebKit

/// Meet state mirrored out of the page, one instance per `WebPage`.
///
/// Meet's own controls are the only reliable source. WebKit's
/// `microphoneCaptureState` reports whether the *platform* is capturing and
/// stays `.active` the whole time Meet is muted (verified 2026-08-05: muting in
/// Meet produces no capture-state change at all), so menu items read from here.
@MainActor
@Observable
final class MeetPageState {
    /// Nil when there is no mic control to read: the landing page, or a call
    /// whose toolbar hasn't rendered yet.
    var isMicrophoneMuted: Bool?

    /// Applies one `meetState` message body. Split out from the message handler
    /// so it can be tested without fabricating a `WKScriptMessage`.
    func apply(_ body: [String: Any]) {
        switch body["type"] as? String {
        case "microphone":
            isMicrophoneMuted = body["muted"] as? Bool
        default:
            break
        }
    }
}

/// Receives `meetState` messages for one page and mirrors them into that page's
/// `MeetPageState`. Retained by the page's `WKUserContentController`.
final class MeetStateHandler: NSObject, WKScriptMessageHandler {
    private let state: MeetPageState

    init(state: MeetPageState) {
        self.state = state
        super.init()
    }

    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        // Only Meet itself gets to describe Meet's controls.
        guard message.frameInfo.securityOrigin.host == "meet.google.com",
              let body = message.body as? [String: Any]
        else { return }

        NSLog("meet state: \(body)")
        state.apply(body)
    }
}
