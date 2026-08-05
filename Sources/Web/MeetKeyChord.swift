import Foundation

/// One keystroke to replay inside Meet. Meet exposes most of its functionality
/// only through keyboard shortcuts, so native menu items drive it by handing a
/// chord to `MeetKeyboard`. The fields map onto the DOM `KeyboardEventInit`
/// members Meet's own handlers read.
struct MeetKeyChord: Equatable {
    let key: String
    let code: String
    /// Legacy `event.keyCode`, which some Meet handlers still read.
    let keyCode: Int
    var shift = false
    var command = false
    var control = false

    /// JSON-serializable payload for bridge.js, passed as a `callJavaScript`
    /// argument.
    var jsInit: [String: Any] {
        [
            "key": key,
            "code": code,
            "keyCode": keyCode,
            "shiftKey": shift,
            "metaKey": command,
            "ctrlKey": control,
        ]
    }
}

extension MeetKeyChord {
    /// Meet's shortcut overlay. Google documents Shift+? for this
    /// (https://support.google.com/a/users/answer/9896256); the native menu
    /// item advertises ⌘/ instead, because a bare `?` key equivalent would
    /// outrank the web view and swallow every literal "?" typed into the page.
    static let showKeyboardShortcuts = MeetKeyChord(
        key: "?",
        code: "Slash",
        keyCode: 191,
        shift: true
    )
}
