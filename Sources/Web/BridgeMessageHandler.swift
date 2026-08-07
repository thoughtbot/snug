import AppKit
import WebKit

/// Receives messages posted by bridge.js from the page world of
/// meet.google.com. One instance is shared by all Meet pages.
final class BridgeMessageHandler: NSObject, WKScriptMessageHandler {
    func userContentController(
        _ userContentController: WKUserContentController,
        didReceive message: WKScriptMessage
    ) {
        let host = message.frameInfo.securityOrigin.host
        // Signed-out meet.google.com redirects to workspace.google.com, so
        // general messages accept any Google host; capture-related messages
        // (added in M4) must come from meet.google.com itself.
        guard host == "google.com" || host.hasSuffix(".google.com"),
              let body = message.body as? [String: Any],
              let type = body["type"] as? String
        else { return }

        switch type {
        case "ready":
            NSLog("bridge ready: \(body["url"] as? String ?? "?")")
            confirmRoundTrip(message.webView)
        case "autoJoined":
            NSLog("auto-joined: \(body["url"] as? String ?? "?")")
        case "autoJoinNoButton":
            // Both matching strategies missed; the buttons actually on the page
            // are the fix, so log them rather than leaving a silent no-op.
            NSLog("auto-join found no button: \(body["buttons"] ?? "none")")
        case "openWindow":
            guard let urlString = body["url"] as? String,
                  let url = URL(string: urlString),
                  url.scheme == "https" || url.scheme == "http"
            else { return }
            // Meet popups (attached Docs, chat links) go through the router:
            // meeting links open in-app, the rest in the fallback browser.
            URLRouter.shared.route(url)
        default:
            NSLog("bridge message ignored: \(type)")
        }
    }

    /// Completes the JS↔Swift round-trip check: calls back into the page
    /// world and logs what the injected script returns.
    private func confirmRoundTrip(_ webView: WKWebView?) {
        webView?.callAsyncJavaScript(
            "return window.__meetBridge ? window.__meetBridge.version : 'missing'",
            arguments: [:],
            in: nil,
            in: .page
        ) { result in
            NSLog("bridge round-trip: \(result)")
        }
    }
}
