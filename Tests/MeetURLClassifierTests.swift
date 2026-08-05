import Foundation
import Testing
@testable import Snug

@Suite struct MeetURLClassifierTests {
    private func classify(_ string: String) -> URLDestination {
        MeetURLClassifier.classify(URL(string: string)!)
    }

    @Test func meetingCodeURLsAreMeet() {
        #expect(classify("https://meet.google.com/abc-defg-hij") == .meet(URL(string: "https://meet.google.com/abc-defg-hij")!))
        #expect(classify("http://meet.google.com/abc-defg-hij") == .meet(URL(string: "http://meet.google.com/abc-defg-hij")!))
        #expect(classify("https://MEET.GOOGLE.COM/abc-defg-hij?authuser=1") == .meet(URL(string: "https://MEET.GOOGLE.COM/abc-defg-hij?authuser=1")!))
    }

    @Test func meetSpecialPathsAreMeet() {
        for path in ["/new", "/landing", "/lookup/abcdef", "/home", "/"] {
            let url = URL(string: "https://meet.google.com\(path)")!
            #expect(MeetURLClassifier.classify(url) == .meet(url), "\(path)")
        }
    }

    @Test func gcoMeetShortlinksAreMeet() {
        let url = URL(string: "https://g.co/meet/abc")!
        #expect(MeetURLClassifier.classify(url) == .meet(url))
    }

    /// Meeter and Google Calendar hand out account-chooser links, not bare
    /// meeting links; without unwrapping they'd forward to the browser.
    @Test func googleRedirectsToMeetAreMeet() {
        #expect(
            classify("https://accounts.google.com/AccountChooser?Email=you@example.com&continue=https://meet.google.com/abc-defg-hij")
                == .meet(URL(string: "https://meet.google.com/abc-defg-hij")!)
        )
        #expect(
            classify("https://accounts.google.com/AccountChooser?Email=you@example.com&continue=https%3A%2F%2Fmeet.google.com%2Fabc-defg-hij%3Fauthuser%3D0")
                == .meet(URL(string: "https://meet.google.com/abc-defg-hij?authuser=0")!)
        )
        #expect(
            classify("https://www.google.com/url?q=https://meet.google.com/abc-defg-hij")
                == .meet(URL(string: "https://meet.google.com/abc-defg-hij")!)
        )
        #expect(
            classify("https://accounts.google.com/ServiceLogin?continue=https://www.google.com/url%3Fq%3Dhttps://meet.google.com/abc-defg-hij")
                == .meet(URL(string: "https://meet.google.com/abc-defg-hij")!)
        )
    }

    /// A wrapper is only as good as its target: Google redirects that don't
    /// lead to Meet still belong in the browser.
    @Test func googleRedirectsElsewhereAreOther() {
        for string in [
            "https://accounts.google.com/AccountChooser?Email=you@example.com&continue=https://mail.google.com/mail/u/0/",
            "https://accounts.google.com/AccountChooser?Email=you@example.com",
            "https://www.google.com/url?q=https://example.com/meet.google.com",
            "https://accounts.google.com/AccountChooser?continue=notaurl",
        ] {
            let url = URL(string: string)!
            #expect(MeetURLClassifier.classify(url) == .other(url), Comment(rawValue: string))
        }
    }

    /// A wrapper unwraps to the meeting itself, so two links to the same
    /// meeting share one window regardless of how they were wrapped.
    @Test func wrappedAndBareLinksShareAWindowValue() {
        let wrapped = classify("https://accounts.google.com/AccountChooser?Email=you@example.com&continue=https://meet.google.com/abc-defg-hij")
        guard case .meet(let wrappedMeet) = wrapped else {
            Issue.record("expected a meeting")
            return
        }
        #expect(
            MeetURLClassifier.windowValue(for: wrappedMeet)
                == MeetURLClassifier.windowValue(for: URL(string: "https://meet.google.com/abc-defg-hij?hs=122")!)
        )
    }

    @Test func everythingElseIsOther() {
        for string in [
            "https://www.google.com/",
            "https://meet.google.com.evil.example/abc",
            "https://notmeet.google.com/abc",
            "https://g.co/maps/xyz",
            "https://example.com/https://meet.google.com/abc",
            "ftp://meet.google.com/abc",
        ] {
            let url = URL(string: string)!
            #expect(MeetURLClassifier.classify(url) == .other(url), Comment(rawValue: string))
        }
    }

    @Test func windowValueStripsVolatileParts() {
        let a = MeetURLClassifier.windowValue(for: URL(string: "https://meet.google.com/abc-defg-hij?authuser=0&hs=122#frag")!)
        let b = MeetURLClassifier.windowValue(for: URL(string: "http://MEET.GOOGLE.COM/abc-defg-hij")!)
        #expect(a == URL(string: "https://meet.google.com/abc-defg-hij")!)
        #expect(a == b)
    }
}
