import Testing
import Foundation
@testable import ScreammKit

@MainActor
struct StatsHookTests {
    final class FakeRecorder: AudioRecording {
        var samples: [Float] = Array(repeating: 0.3, count: 16_000)   // non-silent
        func start() throws {}
        func stop() -> [Float] { samples }
    }
    final class FakeTranscriber: Transcribing {
        func transcribe(_ samples: [Float]) async throws -> String { "hello world here" }
    }
    final class FakeInjector: TextInjecting {
        func inject(_ text: String) {}
    }
    final class FakeStats: StatsRecording {
        var recorded: [(Int, Date)] = []
        var milestoneToReturn: Milestone?
        func recordDictation(wordCount: Int, at date: Date) -> Milestone? {
            recorded.append((wordCount, date)); return milestoneToReturn
        }
    }

    private func waitUntilIdle(_ c: RecordingCoordinator) async {
        for _ in 0..<200 where c.state != .idle { try? await Task.sleep(nanoseconds: 5_000_000) }
    }

    @Test func recordsWordCountAndFiresHooks() async {
        let stats = FakeStats()
        stats.milestoneToReturn = .firstDictation
        let c = RecordingCoordinator(
            recorder: FakeRecorder(), transcriber: FakeTranscriber(),
            injector: FakeInjector(), stats: stats)

        var successWords: Int?
        var milestone: Milestone?
        c.onSuccess = { successWords = $0 }
        c.onMilestone = { milestone = $0 }

        c.handlePress()
        c.handleRelease()
        await waitUntilIdle(c)

        #expect(stats.recorded.count == 1)
        #expect(stats.recorded.first?.0 == 3)   // "hello world here" → 3 words
        #expect(successWords == 3)
        #expect(milestone == .firstDictation)
    }
}
