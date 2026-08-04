import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSLog("Snug launched")
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        for url in urls {
            URLRouter.shared.route(url)
        }
    }
}
