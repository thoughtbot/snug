import SwiftUI
import WebKit

/// The Meet page a command should act on, plus whether it can actually be
/// driven right now. `isInMeeting` is resolved by `MeetWebView` rather than
/// here so that reading `page.url` registers as an observation dependency and
/// menus update when a window navigates from the landing page into a call.
struct FocusedMeetPage: Equatable {
    let page: WebPage
    let isInMeeting: Bool

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.page === rhs.page && lhs.isInMeeting == rhs.isInMeeting
    }
}

private struct FocusedMeetPageKey: FocusedValueKey {
    typealias Value = FocusedMeetPage
}

extension FocusedValues {
    /// The Meet page in the frontmost window, published by `MeetWebView`. Menu
    /// commands act on this rather than a fixed page, so they follow focus
    /// across the home window and every meeting window — and go inert when
    /// something else (e.g. Settings) is frontmost.
    var meetPage: FocusedMeetPage? {
        get { self[FocusedMeetPageKey.self] }
        set { self[FocusedMeetPageKey.self] = newValue }
    }
}

/// Menu items that trigger behavior inside Google Meet.
struct MeetCommands: Commands {
    @FocusedValue(\.meetPage) private var meet

    /// The page for items that only work mid-call. Nil on the Meet landing
    /// page and when a non-Meet window (e.g. Settings) is frontmost, which
    /// greys those items out instead of letting them silently do nothing.
    private var inMeeting: WebPage? {
        guard let meet, meet.isInMeeting else { return nil }
        return meet.page
    }

    var body: some Commands {
        // Replaces the default "Snug Help" item, which leads nowhere: there is
        // no help book in the bundle.
        CommandGroup(replacing: .help) {
            Button("Google Meet Keyboard Shortcuts") {
                if let inMeeting {
                    MeetKeyboard.send(.showKeyboardShortcuts, to: inMeeting)
                }
            }
            .keyboardShortcut("/", modifiers: .command)
            .disabled(inMeeting == nil)
        }
    }
}
