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

    static func broadcastHideSelf(_ enabled: Bool) {
        pages.removeAll { $0.page == nil }
        for entry in pages {
            guard let page = entry.page else { continue }
            Task {
                _ = try? await page.callJavaScript(
                    "window.__snugHideSelf = enabled",
                    arguments: ["enabled": enabled],
                    contentWorld: .page
                )
            }
        }
    }
}
