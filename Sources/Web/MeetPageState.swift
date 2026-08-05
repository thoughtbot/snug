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
    /// Each is nil when Meet exposes no such control to read: the landing page,
    /// or a call whose toolbar hasn't rendered yet. bridge.js normalizes all of
    /// them to "on", since Meet marks each control differently and the markup
    /// doesn't agree about polarity (`data-is-muted` true means off, while
    /// `aria-pressed` and `aria-expanded` true mean on).
    var isMicrophoneOn: Bool?
    var isCameraOn: Bool?
    var isHandRaised: Bool?
    var isChatOpen: Bool?

    /// Applies one `meetState` message body. Split out from the message handler
    /// so it can be tested without fabricating a `WKScriptMessage`.
    func apply(_ body: [String: Any]) {
        let on = body["on"] as? Bool
        switch body["type"] as? String {
        case "microphone":
            isMicrophoneOn = on
        case "camera":
            isCameraOn = on
        case "hand":
            isHandRaised = on
        case "chat":
            isChatOpen = on
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
