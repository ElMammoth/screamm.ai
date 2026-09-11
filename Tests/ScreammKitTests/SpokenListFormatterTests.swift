import Testing
import Foundation
@testable import ScreammKit

struct SpokenListFormatterTests {
    let f = SpokenListFormatter()

    // MARK: Auto-detect (ordinals)

    @Test func ordinalsBecomeNumberedList() {
        let out = f.format("First, buy milk. Second, call mom. Third, ship v0.3")
        #expect(out == "1. Buy milk\n2. Call mom\n3. Ship v0.3")
    }

    @Test func worksWithoutPunctuation() {
        // Whisper doesn't always punctuate a spoken list.
        let out = f.format("first buy milk second call mom third ship it")
        #expect(out == "1. Buy milk\n2. Call mom\n3. Ship it")
    }

    @Test func loneOrdinalStaysProse() {
        let input = "First, I went to the store and it was closed"
        #expect(f.format(input) == input)   // only one ordinal → not a list
    }

    @Test func gapInOrdinalsIsRejected() {
        let input = "First, buy milk. Third, ship it"
        #expect(f.format(input) == input)   // first→third skips second → not a list
    }

    @Test func ordinalWithNoContentIsRejected() {
        // "I was first and she was second" — trailing ordinal has no item content.
        let input = "I was first and she was second"
        #expect(f.format(input) == input)
    }

    @Test func preambleIsKeptAboveTheList() {
        let out = f.format("Here is my plan. First, buy milk. Second, call mom")
        #expect(out.hasPrefix("Here is my plan"))
        #expect(out.contains("1. Buy milk"))
        #expect(out.contains("2. Call mom"))
    }

    // MARK: Explicit separators + directives

    @Test func separatorsBecomeBulletList() {
        let out = f.format("buy milk new bullet call mom new bullet ship it")
        #expect(out == "- Buy milk\n- Call mom\n- Ship it")
    }

    @Test func nextItemAlsoSeparates() {
        let out = f.format("eggs next item bread next item coffee")
        #expect(out == "- Eggs\n- Bread\n- Coffee")
    }

    @Test func numberedDirectiveForcesNumbers() {
        let out = f.format("numbered list buy milk new bullet call mom")
        #expect(out == "1. Buy milk\n2. Call mom")
    }

    @Test func bulletDirectiveWithOrdinals() {
        let out = f.format("bullet list first buy milk second call mom")
        #expect(out == "- Buy milk\n- Call mom")
    }

    @Test func singleSeparatorItemIsNotAList() {
        let input = "just one thing"
        #expect(f.format(input) == input)
    }

    // MARK: end list

    @Test func endListKeepsTrailingProse() {
        let out = f.format("first buy milk second call mom end list that is everything")
        #expect(out.contains("1. Buy milk"))
        #expect(out.contains("2. Call mom"))
        #expect(out.hasSuffix("that is everything"))
    }

    // MARK: Code mode

    @Test func codeModeDoesNotCapitalizeItems() {
        let out = f.format("first buildProject second runTests", capitalizeItems: false)
        #expect(out == "1. buildProject\n2. runTests")
    }

    // MARK: Pipeline integration

    @Test func pipelineFormatsSpokenList() {
        let out = CleanupPipeline().process("um first buy milk second call mom third ship it")
        #expect(out == "1. Buy milk\n2. Call mom\n3. Ship it")
    }

    @Test func pipelineLeavesNormalProseAlone() {
        let out = CleanupPipeline().process("first I went to the store")
        #expect(out == "First I went to the store")
    }
}
