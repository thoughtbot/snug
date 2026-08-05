import Foundation
import Testing
@testable import Snug

@Suite @MainActor struct MeetPageStateTests {
    @Test func controlMessagesSetOnState() {
        let state = MeetPageState()
        #expect(state.isMicrophoneOn == nil)

        state.apply(["type": "microphone", "on": true])
        #expect(state.isMicrophoneOn == true)

        state.apply(["type": "microphone", "on": false])
        #expect(state.isMicrophoneOn == false)
    }

    /// bridge.js reports null once a control disappears (call ended), and that
    /// has to clear back to "unknown" so the menu item disables rather than
    /// keeping the last call's state.
    @Test func missingValueClearsBackToUnknown() {
        let state = MeetPageState()
        state.apply(["type": "microphone", "on": true])

        state.apply(["type": "microphone", "on": NSNull()])
        #expect(state.isMicrophoneOn == nil)

        state.apply(["type": "microphone", "on": true])
        state.apply(["type": "microphone"])
        #expect(state.isMicrophoneOn == nil)
    }

    /// Every control shares one message shape and one poll, so a report for one
    /// must not disturb the others.
    @Test func controlsTrackIndependently() {
        let state = MeetPageState()

        state.apply(["type": "microphone", "on": false])
        state.apply(["type": "camera", "on": true])
        state.apply(["type": "hand", "on": true])
        state.apply(["type": "chat", "on": false])
        #expect(state.isMicrophoneOn == false)
        #expect(state.isCameraOn == true)
        #expect(state.isHandRaised == true)
        #expect(state.isChatOpen == false)

        state.apply(["type": "chat", "on": true])
        #expect(state.isMicrophoneOn == false)
        #expect(state.isCameraOn == true)
        #expect(state.isHandRaised == true)
        #expect(state.isChatOpen == true)
    }

    @Test func unrelatedMessagesAreIgnored() {
        let state = MeetPageState()
        state.apply(["type": "microphone", "on": true])

        state.apply(["type": "somethingElse", "on": false])
        state.apply([:])
        #expect(state.isMicrophoneOn == true)
    }
}
