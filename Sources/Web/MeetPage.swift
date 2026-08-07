import AVFoundation
import Foundation
import WebKit

/// Builds and owns the `WebPage` instances that host meet.google.com.
@MainActor
enum MeetPageFactory {
    /// Byte-for-byte Safari UA for this OS; Google's sign-in flow rejects
    /// anything it can't identify as a real browser. Version token matches
    /// the installed Safari (26.5.2 → "26.5").
    static let safariUserAgent =
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 "
        + "(KHTML, like Gecko) Version/26.5 Safari/605.1.15"

    static let homeURL = URL(string: "https://meet.google.com/")!

    /// `state` is per page: it receives that page's `meetState` messages, and
    /// the window's view reads it to draw menu state.
    static func makePage(bridge: BridgeMessageHandler, state: MeetPageState) -> WebPage {
        var configuration = WebPage.Configuration()
        configuration.websiteDataStore = .default()
        configuration.deviceSensorAuthorization = .init { permission, _, origin in
            guard case .mediaCapture(let captureType) = permission else { return .deny }
            guard origin.host == "meet.google.com" else { return .deny }
            return await ensureSystemMediaAccess(for: captureType) ? .grant : .deny
        }

        let controller = WKUserContentController()
        // Preference flags must exist before bridge.js reads them.
        controller.addUserScript(WKUserScript(
            source: """
                window.\(SnugFlag.hideSelfView.rawValue) = \(Preferences.hideSelfView);
                window.\(SnugFlag.autoJoin.rawValue) = \(Preferences.autoJoin);
                """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true,
            in: .page
        ))
        if let script = bridgeScriptSource() {
            controller.addUserScript(WKUserScript(
                source: script,
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true,
                in: .page
            ))
        }
        controller.add(bridge, contentWorld: .page, name: "meetBridge")
        controller.add(MeetStateHandler(state: state), contentWorld: .page, name: "meetState")
        configuration.userContentController = controller

        let page = WebPage(configuration: configuration)
        page.customUserAgent = safariUserAgent
        PageRegistry.register(page)
        return page
    }

    private static func bridgeScriptSource() -> String? {
        guard let url = Bundle.main.url(forResource: "bridge", withExtension: "js") else {
            NSLog("bridge.js missing from bundle")
            return nil
        }
        return try? String(contentsOf: url, encoding: .utf8)
    }

    /// macOS-level TCC prompt; WebKit's per-origin grant only works once the
    /// app itself has camera/mic access.
    private static func ensureSystemMediaAccess(for type: WKMediaCaptureType) async -> Bool {
        switch type {
        case .camera:
            return await AVCaptureDevice.requestAccess(for: .video)
        case .microphone:
            return await AVCaptureDevice.requestAccess(for: .audio)
        case .cameraAndMicrophone:
            let video = await AVCaptureDevice.requestAccess(for: .video)
            let audio = await AVCaptureDevice.requestAccess(for: .audio)
            return video && audio
        @unknown default:
            return false
        }
    }
}
