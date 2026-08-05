import SwiftUI
import WebKit

/// The Meet page a command should act on, plus the state commands need to
/// decide whether they apply and how to draw themselves. Every field here is
/// resolved by `MeetWebView` rather than read inside a command, so that reading
/// it registers as an observation dependency and menus update when the page
/// navigates into a call or the mic changes.
///
/// Anything added here must join `==` too, or SwiftUI won't republish the
/// focused value when it changes and the menu will go stale.
struct FocusedMeetPage: Equatable {
    let page: WebPage
    let isInMeeting: Bool
    let isMicrophoneOn: Bool?
    let isCameraOn: Bool?
    let isHandRaised: Bool?

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.page === rhs.page
            && lhs.isInMeeting == rhs.isInMeeting
            && lhs.isMicrophoneOn == rhs.isMicrophoneOn
            && lhs.isCameraOn == rhs.isCameraOn
            && lhs.isHandRaised == rhs.isHandRaised
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

    /// Whether a control is on, or nil when there is nothing to drive: outside
    /// a call, or before Meet has rendered its toolbar.
    private func state(_ control: KeyPath<FocusedMeetPage, Bool?>) -> Bool? {
        guard inMeeting != nil, let meet else { return nil }
        return meet[keyPath: control]
    }

    /// One Meet control as a checkable menu item.
    ///
    /// `Toggle`, not `Button`: it's what renders a checkmark. The binding is
    /// unusual — writing to it ignores the requested value and just asks Meet
    /// to toggle, because Meet offers one chord for both directions. The real
    /// new state arrives back from Meet's own button via `MeetPageState`, which
    /// is what keeps the checkmark honest when a control is used on screen
    /// rather than from this menu.
    private func control(
        _ title: String,
        on: Bool?,
        chord: MeetKeyChord,
        key: KeyEquivalent,
        modifiers: EventModifiers = .command
    ) -> some View {
        Toggle(title, isOn: Binding(
            get: { on == true },
            set: { _ in
                if let inMeeting { MeetKeyboard.send(chord, to: inMeeting) }
            }
        ))
        .keyboardShortcut(key, modifiers: modifiers)
        .disabled(on == nil)
    }

    var body: some Commands {
        CommandMenu("Meeting") {
            control(
                "Microphone",
                on: state(\.isMicrophoneOn),
                chord: .toggleMicrophone,
                key: "d"
            )
            control(
                "Camera",
                on: state(\.isCameraOn),
                chord: .toggleCamera,
                key: "e"
            )
            control(
                "Hand Raised",
                on: state(\.isHandRaised),
                chord: .toggleHand,
                key: "h",
                modifiers: [.control, .command]
            )
        }

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
