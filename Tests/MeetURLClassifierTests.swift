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
