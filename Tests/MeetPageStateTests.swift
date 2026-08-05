import Foundation
import Testing
@testable import Snug

@Suite @MainActor struct MeetPageStateTests {
    @Test func microphoneMessagesSetMuteState() {
        let state = MeetPageState()
        #expect(state.isMicrophoneMuted == nil)

        state.apply(["type": "microphone", "muted": true])
        #expect(state.isMicrophoneMuted == true)

        state.apply(["type": "microphone", "muted": false])
        #expect(state.isMicrophoneMuted == false)
    }

    /// bridge.js reports null once the mic control disappears (call ended), and
    /// that has to clear back to "unknown" so the menu item disables rather
    /// than keeping the last call's state.
    @Test func missingMuteValueClearsBackToUnknown() {
        let state = MeetPageState()
        state.apply(["type": "microphone", "muted": true])

        state.apply(["type": "microphone", "muted": NSNull()])
        #expect(state.isMicrophoneMuted == nil)

        state.apply(["type": "microphone", "muted": true])
        state.apply(["type": "microphone"])
        #expect(state.isMicrophoneMuted == nil)
    }

    @Test func unrelatedMessagesAreIgnored() {
        let state = MeetPageState()
        state.apply(["type": "microphone", "muted": true])

        state.apply(["type": "somethingElse", "muted": false])
        state.apply([:])
        #expect(state.isMicrophoneMuted == true)
    }
}
