import Foundation
import WebKit

/// Drives Meet from native UI by replaying keystrokes in the page. Meet's
/// features are reachable almost exclusively through its own keyboard
/// shortcuts, so this is the shared path for every Meet-triggering menu item.
@MainActor
enum MeetKeyboard {
    static func send(_ chord: MeetKeyChord, to page: WebPage) {
        Task {
            let handled = try? await page.callJavaScript(
                "return window.__meetBridge?.dispatchKey(chord)",
                arguments: ["chord": chord.jsInit],
                contentWorld: .page
            )
            NSLog("meet key \(chord.key): handled=\(handled ?? "?")")
        }
    }
}
