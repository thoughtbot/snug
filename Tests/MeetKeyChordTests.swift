import Foundation
import Testing
@testable import Snug

@Suite struct MeetKeyChordTests {
    /// The payload Meet's handler sees. Getting any of these wrong fails
    /// silently in the page, so pin them.
    @Test func showKeyboardShortcutsIsShiftQuestionMark() {
        let payload = MeetKeyChord.showKeyboardShortcuts.jsInit
        #expect(payload["key"] as? String == "?")
        #expect(payload["code"] as? String == "Slash")
        #expect(payload["keyCode"] as? Int == 191)
        #expect(payload["shiftKey"] as? Bool == true)
        #expect(payload["metaKey"] as? Bool == false)
        #expect(payload["ctrlKey"] as? Bool == false)
    }

    @Test func toggleMicrophoneIsCommandD() {
        let payload = MeetKeyChord.toggleMicrophone.jsInit
        #expect(payload["key"] as? String == "d")
        #expect(payload["code"] as? String == "KeyD")
        #expect(payload["keyCode"] as? Int == 68)
        #expect(payload["metaKey"] as? Bool == true)
        #expect(payload["shiftKey"] as? Bool == false)
        #expect(payload["ctrlKey"] as? Bool == false)
    }

    @Test func toggleCameraIsCommandE() {
        let payload = MeetKeyChord.toggleCamera.jsInit
        #expect(payload["key"] as? String == "e")
        #expect(payload["code"] as? String == "KeyE")
        #expect(payload["keyCode"] as? Int == 69)
        #expect(payload["metaKey"] as? Bool == true)
        #expect(payload["shiftKey"] as? Bool == false)
        #expect(payload["ctrlKey"] as? Bool == false)
    }

    @Test func toggleHandIsControlCommandH() {
        let payload = MeetKeyChord.toggleHand.jsInit
        #expect(payload["key"] as? String == "h")
        #expect(payload["code"] as? String == "KeyH")
        #expect(payload["keyCode"] as? Int == 72)
        #expect(payload["metaKey"] as? Bool == true)
        #expect(payload["ctrlKey"] as? Bool == true)
        #expect(payload["shiftKey"] as? Bool == false)
    }

    /// Unset modifiers must serialize as `false`, not go missing: bridge.js
    /// spreads this straight into KeyboardEventInit.
    @Test func everyModifierIsAlwaysPresent() {
        let payload = MeetKeyChord(key: "d", code: "KeyD", keyCode: 68, command: true).jsInit
        #expect(payload["metaKey"] as? Bool == true)
        #expect(payload["shiftKey"] as? Bool == false)
        #expect(payload["ctrlKey"] as? Bool == false)
    }
}
