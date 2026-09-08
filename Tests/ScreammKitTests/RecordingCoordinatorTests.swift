import Testing
import Foundation
@testable import ScreammKit

@MainActor
struct RecordingCoordinatorTests {

    // MARK: Fakes

    final class FakeRecorder: AudioRecording {
        var samples: [Float] = []
        var startCount = 0
        func start() throws { startCount += 1 }
        func stop() -> [Float] { samples }
    }

    final class FakeTranscriber: Transcribing {
        var text = "hello world"
        func transcribe(_ samples: [Float]) async throws -> String { text }
    }

    final class FakeInjector: TextInjecting {
        var injected: [String] = []
        func inject(_ text: String) { injected.append(text) }
    }

    // one second of audio = comfortably above the min-duration gate
    private func oneSecond() -> [Float] { [Float](repeating: 0, count: 16_000) }

    private func waitUntilIdle(_ c: RecordingCoordinator) async {
        for _ in 0..<200 where c.state != .idle {
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
    }

    // MARK: Tests

    @Test func pressWhileRecordingIsIgnored() {
        let recorder = FakeRecorder()
        let c = RecordingCoordinator(recorder: recorder, transcriber: FakeTranscriber(), injector: FakeInjector())
        c.handlePress()
        c.handlePress() // should be ignored — no overlap
        #expect(recorder.startCount == 1)
        #expect(c.state == .recording)
    }

    @Test func shortTapIsDiscarded() async {
        let recorder = FakeRecorder()
        recorder.samples = [Float](repeating: 0, count: 100) // ~6ms, under the gate
        let injector = FakeInjector()
        let c = RecordingCoordinator(recorder: recorder, transcriber: FakeTranscriber(), injector: injector)
        c.handlePress()
        c.handleRelease()
        await waitUntilIdle(c)
        #expect(injector.injected.isEmpty)
        #expect(c.state == .idle)
    }

    @Test func fullFlowInjectsCleanedText() async {
        let recorder = FakeRecorder()
        recorder.samples = oneSecond()
        let injector = FakeInjector()
        let c = RecordingCoordinator(recorder: recorder, transcriber: FakeTranscriber(), injector: injector)
        c.handlePress()
        c.handleRelease()
        await waitUntilIdle(c)
        #expect(injector.injected == ["Hello world"]) // cleanup capitalized it
        #expect(c.state == .idle)
    }

    @Test func emptyTranscriptIsSuppressed() async {
        let recorder = FakeRecorder()
        recorder.samples = oneSecond()
        let transcriber = FakeTranscriber()
        transcriber.text = "   " // silence/hallucination → empty after cleanup
        let injector = FakeInjector()
        let c = RecordingCoordinator(recorder: recorder, transcriber: transcriber, injector: injector)
        c.handlePress()
        c.handleRelease()
        await waitUntilIdle(c)
        #expect(injector.injected.isEmpty)
        #expect(c.state == .idle)
    }
}
