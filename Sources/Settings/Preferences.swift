import Foundation

/// Preference flags mirrored onto `window` for bridge.js to read. Named here so
/// the injected initial value and the live update can't drift apart.
enum SnugFlag: String {
    case hideSelfView = "__snugHideSelf"
    case autoJoin = "__snugAutoJoin"
}

@MainActor
enum Preferences {
    private static let hideSelfViewKey = "hideSelfView"
    private static let autoJoinKey = "autoJoin"

    /// Hide your own video tile once others join a call. Defaults to on.
    static var hideSelfView: Bool {
        get {
            UserDefaults.standard.object(forKey: hideSelfViewKey) == nil
                ? true
                : UserDefaults.standard.bool(forKey: hideSelfViewKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hideSelfViewKey)
            PageRegistry.broadcast(.hideSelfView, enabled: newValue)
        }
    }

    /// Skip Meet's "Ready to join?" screen and join as soon as a meeting opens.
    /// Defaults to off — it gives up the last chance to check your camera and
    /// mic before other people can see and hear you.
    static var autoJoin: Bool {
        get { UserDefaults.standard.bool(forKey: autoJoinKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: autoJoinKey)
            PageRegistry.broadcast(.autoJoin, enabled: newValue)
        }
    }
}
