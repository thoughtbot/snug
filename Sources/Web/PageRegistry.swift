import WebKit

/// Weakly tracks every live WebPage so preference changes can be pushed
/// into already-open windows.
@MainActor
enum PageRegistry {
    private final class WeakPage {
        weak var page: WebPage?
        init(_ page: WebPage) { self.page = page }
    }

    private static var pages: [WeakPage] = []

    static func register(_ page: WebPage) {
        pages.removeAll { $0.page == nil }
        pages.append(WeakPage(page))
    }

    /// Pushes a preference flag into every open page. The flag name travels as
    /// an argument rather than interpolated into the source, so the script here
    /// stays fixed no matter what gets added to `SnugFlag`.
    static func broadcast(_ flag: SnugFlag, enabled: Bool) {
        pages.removeAll { $0.page == nil }
        for entry in pages {
            guard let page = entry.page else { continue }
            Task {
                _ = try? await page.callJavaScript(
                    "window[flag] = enabled",
                    arguments: ["flag": flag.rawValue, "enabled": enabled],
                    contentWorld: .page
                )
            }
        }
    }
}
