import SwiftUI
import WebKit

@MainActor
@Observable
final class AppModel {
    let bridge = BridgeMessageHandler()
    let homePage: WebPage

    init() {
        homePage = MeetPageFactory.makePage(bridge: bridge)
    }
}

@main
struct SnugApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = AppModel()

    var body: some Scene {
        Window("Snug", id: "home") {
            HomeWindowView()
                .environment(model)
        }
        .commands {
            CommandGroup(after: .toolbar) {
                Button("Reload") { model.homePage.reload() }
                    .keyboardShortcut("r")
            }
            MeetCommands()
        }

        WindowGroup(id: "meeting", for: URL.self) { $url in
            MeetingWindowView(url: url)
                .environment(model)
        }
        .defaultSize(width: 1100, height: 720)
        // A meeting is over when the window closes, and macOS restores these
        // windows without their URL anyway — which lands them on the Meet
        // landing page, looking like a stray second home window.
        .restorationBehavior(.disabled)

        Settings {
            SettingsView()
        }
    }
}

/// Home window: the signed-in meet.google.com landing page. Also registers
/// the meeting-window opener and its own dismissal with the router (the
/// captured actions stay valid after the registering window closes).
private struct HomeWindowView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    var body: some View {
        MeetWebView(page: model.homePage)
            .onAppear {
                URLRouter.shared.openMeetingWindow = { url in
                    openWindow(id: "meeting", value: url)
                }
                URLRouter.shared.dismissHomeWindow = {
                    dismissWindow(id: "home")
                }
            }
    }
}

/// One window per meeting; its WebPage lives and dies with the window.
private struct MeetingWindowView: View {
    @Environment(AppModel.self) private var model
    let url: URL?
    @State private var page: WebPage?

    var body: some View {
        Group {
            if let page {
                MeetWebView(page: page)
            } else {
                Color.clear
            }
        }
        .onAppear {
            if page == nil {
                let newPage = MeetPageFactory.makePage(bridge: model.bridge)
                newPage.load(URLRequest(url: url ?? MeetPageFactory.homeURL))
                page = newPage
            }
        }
    }
}
