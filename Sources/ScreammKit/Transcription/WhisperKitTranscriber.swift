import Foundation
import WhisperKit

/// WhisperKit-backed transcription. Keeps the model resident AND warm — "resident" alone
/// isn't enough because CoreML re-JITs the ANE after idle (eng-review finding), so we run
/// a warm-up inference at load and expose `warmUp()` for the app to call periodically.
public final class WhisperKitTranscriber: Transcribing {

    private var pipe: WhisperKit?
    private let modelName: String

    /// `large-v3-v20240930_turbo` is the identifier the engine spike verified downloads
    /// and runs (1.83s warm on M2 Pro). `large-v3` is the optional max-accuracy download.
    public init(model: String = "large-v3-v20240930_turbo") {
        self.modelName = model
    }

    /// Download (first run) + load the model onto the ANE, then warm it up. Call once at
    /// launch before the first dictation.
    public func load() async throws {
        let config = WhisperKitConfig(model: modelName)
        let pipe = try await WhisperKit(config)
        self.pipe = pipe
        await warmUp()
    }

    /// A throwaway inference over 1s of silence to force the ANE JIT. Cheap; call on a
    /// timer during idle to keep the first real decode fast.
    public func warmUp() async {
        guard let pipe else { return }
        _ = try? await pipe.transcribe(audioArray: [Float](repeating: 0, count: Int(whisperSampleRate)))
    }

    public func transcribe(_ samples: [Float]) async throws -> String {
        guard let pipe else { throw TranscriberError.notLoaded }
        let results = try await pipe.transcribe(audioArray: samples)
        return results
            .map { $0.text }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

public enum TranscriberError: Error {
    case notLoaded
}
