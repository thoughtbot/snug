import Foundation

@MainActor
enum Preferences {
    private static let hideSelfViewKey = "hideSelfView"

    /// Hide your own video tile once others join a call. Defaults to on.
    static var hideSelfView: Bool {
        get {
            UserDefaults.standard.object(forKey: hideSelfViewKey) == nil
                ? true
                : UserDefaults.standard.bool(forKey: hideSelfViewKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hideSelfViewKey)
            PageRegistry.broadcastHideSelf(newValue)
        }
    }
}
