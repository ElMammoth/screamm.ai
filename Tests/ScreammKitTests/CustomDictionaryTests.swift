import Testing
import Foundation
@testable import ScreammKit

struct CustomDictionaryTests {
    func dict(_ pairs: [(String, String)]) -> CustomDictionary {
        CustomDictionary(entries: pairs.map { .init(from: $0.0, to: $0.1) })
    }

    @Test func replacesWholeWord() {
        #expect(dict([("screen", "Screamm")]).apply(to: "screen is great") == "Screamm is great")
    }

    @Test func caseInsensitiveMatchKeepsReplacementCase() {
        #expect(dict([("screen", "Screamm")]).apply(to: "Screen rocks") == "Screamm rocks")
    }

    @Test func doesNotTouchSubstrings() {
        // "screenshot" must survive a "screen" rule (word boundary).
        #expect(dict([("screen", "Screamm")]).apply(to: "take a screenshot") == "take a screenshot")
    }

    @Test func replacesPhrase() {
        #expect(dict([("screen a i", "Screamm.ai")]).apply(to: "open screen a i now") == "open Screamm.ai now")
    }

    @Test func emptyFromIsIgnored() {
        #expect(dict([("", "X")]).apply(to: "hello") == "hello")
    }

    @Test func replacementWithSpecialCharsIsLiteral() {
        // '$' in the replacement must not be treated as a regex template reference.
        #expect(dict([("dollars", "$100")]).apply(to: "five dollars please") == "five $100 please")
    }

    @Test func multipleEntriesApply() {
        let d = dict([("screen", "Screamm"), ("mack", "Mac")])
        #expect(d.apply(to: "screen on my mack") == "Screamm on my Mac")
    }

    @Test func emptyDictionaryIsNoOp() {
        #expect(CustomDictionary().apply(to: "nothing changes") == "nothing changes")
    }
}
