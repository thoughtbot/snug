import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    /// URLs arrive before this notification (AppKit delivers them between
    /// `willFinishLaunching` and here), so a meeting window already open by
    /// now means the launch existed only to join that meeting — and the home
    /// window SwiftUI opened alongside it is a second, unwanted window.
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Snug launched")
        if URLRouter.shared.didOpenMeetingWindow {
            URLRouter.shared.dismissHomeWindow?()
        }
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            URLRouter.shared.route(url)
        }
    }
}
