import Foundation

enum URLDestination: Equatable {
    case meet(URL)
    case other(URL)
}

/// Pure classification of incoming URLs; everything the app receives as a
/// (default) browser flows through here.
enum MeetURLClassifier {
    /// Google hosts that redirect to a target URL carried in a query param.
    /// Meeter and Google Calendar hand out account-chooser links rather than
    /// bare meeting links, e.g.
    /// `accounts.google.com/AccountChooser?Email=you@example.com&continue=https://meet.google.com/abc-defg-hij`.
    private static let redirectHosts: Set<String> = [
        "accounts.google.com",
        "google.com",
        "www.google.com",
    ]

    /// Query params those hosts use to carry the target URL.
    private static let redirectParams = ["continue", "q", "url", "next", "destination"]

    /// Wrappers nest (an account chooser whose `continue` is another
    /// redirect); bounded so a self-referential link can't loop.
    private static let maxUnwrapDepth = 3

    static func classify(_ url: URL) -> URLDestination {
        if let meetURL = meetURL(in: url) { return .meet(meetURL) }
        return .other(url)
    }

    /// The Meet URL this link ultimately points at, unwrapping Google
    /// redirect wrappers, or nil if it doesn't lead to Meet.
    private static func meetURL(in url: URL, depth: Int = 0) -> URL? {
        guard let scheme = url.scheme?.lowercased(),
              scheme == "http" || scheme == "https",
              let host = url.host()?.lowercased()
        else { return nil }

        if host == "meet.google.com" { return url }
        if host == "g.co", url.path().lowercased().hasPrefix("/meet") { return url }

        guard depth < maxUnwrapDepth, redirectHosts.contains(host) else { return nil }
        return redirectTargets(of: url)
            .lazy
            .compactMap { meetURL(in: $0, depth: depth + 1) }
            .first
    }

    /// Absolute http(s) URLs carried in this URL's redirect query params.
    private static func redirectTargets(of url: URL) -> [URL] {
        guard let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        else { return [] }
        return items.compactMap { item in
            guard redirectParams.contains(item.name.lowercased()),
                  let value = item.value,
                  let target = URL(string: value),
                  target.scheme != nil
            else { return nil }
            return target
        }
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
