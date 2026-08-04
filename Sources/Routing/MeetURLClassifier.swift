import Foundation

enum URLDestination: Equatable {
    case meet(URL)
    case other(URL)
}

/// Pure classification of incoming URLs; everything the app receives as a
/// (default) browser flows through here.
enum MeetURLClassifier {
    static func classify(_ url: URL) -> URLDestination {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host()?.lowercased()
        else { return .other(url) }

        if host == "meet.google.com" { return .meet(url) }
        if host == "g.co", url.path().lowercased().hasPrefix("/meet") { return .meet(url) }
        return .other(url)
    }

    /// Stable identity for a meeting so a second click on the same link
    /// focuses the existing window instead of opening a duplicate.
    /// Meeting URLs carry volatile query params (e.g. ?authuser=0&hs=122).
    static func windowValue(for url: URL) -> URL {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.scheme = "https"
        components?.host = url.host()?.lowercased()
        components?.query = nil
        components?.fragment = nil
        return components?.url ?? url
    }
}
