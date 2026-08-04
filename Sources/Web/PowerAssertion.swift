import Foundation
import IOKit.pwr_mgt

/// Keeps the display awake while a call is active. One instance per web
/// view; assertions from multiple windows stack safely.
final class PowerAssertion {
    private var assertionID = IOPMAssertionID(0)
    private var isActive = false

    func setActive(_ newValue: Bool) {
        guard newValue != isActive else { return }
        isActive = newValue
        if newValue {
            IOPMAssertionCreateWithName(
                kIOPMAssertionTypeNoDisplaySleep as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                "Snug call in progress" as CFString,
                &assertionID
            )
        } else {
            IOPMAssertionRelease(assertionID)
        }
    }

    deinit {
        if isActive {
            IOPMAssertionRelease(assertionID)
        }
    }
}
