import Testing
@testable import ScreammKit

struct CleanupPipelineTests {
    let pipeline = CleanupPipeline()

    @Test func stripsStandaloneFillers() {
        #expect(pipeline.stripFillers("um hello uh world") == "hello world")
    }

    @Test func keepsFillerInsideWords() {
        // "drummer"/"hummed" contain "um" but must not be touched.
        #expect(pipeline.stripFillers("the drummer hummed") == "the drummer hummed")
    }

    @Test func newLineCommandStandalone() {
        #expect(pipeline.applySpokenCommands("new line") == "\n")
    }

    @Test func newParagraphCommandBetweenSentences() {
        #expect(pipeline.applySpokenCommands("first. new paragraph. second").contains("\n\n"))
    }

    @Test func literalNewLineInProseSurvives() {
        // No sentence boundary around it → treat as prose, not a command.
        #expect(pipeline.applySpokenCommands("start a new line here") == "start a new line here")
    }

    @Test func capitalizesSentenceStarts() {
        #expect(pipeline.fixCapitalizationAndSpacing("hello world. how are you?") == "Hello world. How are you?")
    }

    @Test func collapsesRunsOfSpaces() {
        #expect(pipeline.fixCapitalizationAndSpacing("hello    world") == "Hello world")
    }

    @Test func emptyOrWhitespaceStaysEmpty() {
        #expect(pipeline.process("   ") == "")
    }

    @Test func fullPipelineHappyPath() {
        #expect(pipeline.process("um hello   world") == "Hello world")
    }
}
