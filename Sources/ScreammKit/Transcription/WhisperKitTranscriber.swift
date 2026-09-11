import Foundation
import WhisperKit

/// Model load lifecycle, observed by onboarding + the menu bar. Delivered on the main thread.
public enum LoadState: Sendable, Equatable {
    case idle
    case downloading(Double)   // 0...1
    case warming
    case ready
    case failed(String)
}

/// WhisperKit-backed transcription. Keeps the model resident AND warm (CoreML re-JITs the ANE
/// after idle, so we run a warm-up inference at load).
///
/// Two-step load (eng review): `WhisperKit.download(progressCallback:)` for a REAL percentage,
/// then construct from the local folder with `download: false`. The single-call init gives no progress.
public final class WhisperKitTranscriber: Transcribing {

    private var pipe: WhisperKit?
    private let modelName: String

    public private(set) var loadState: LoadState = .idle
    /// Observed by onboarding + menu bar. Always called on the main thread.
    public var onLoadStateChange: ((LoadState) -> Void)?

    /// `large-v3-v20240930_turbo` is the identifier the spike verified (1.83s warm on M2 Pro).
    public init(model: String = "large-v3-v20240930_turbo") {
        self.modelName = model
    }

    /// Download (first run, with progress) + load onto the ANE + warm up. Non-throwing: failure
    /// is reported via `loadState = .failed`. Idempotent-ish: safe to call once at launch.
    public func load() async {
        setState(.downloading(0))
        do {
            let folder = try await WhisperKit.download(
                variant: modelName,
                progressCallback: { [weak self] progress in
                    self?.setState(.downloading(progress.fractionCompleted))
                })
            setState(.warming)
            let config = WhisperKitConfig(model: modelName, modelFolder: folder.path, download: false)
            let pipe = try await WhisperKit(config)
            self.pipe = pipe
            await warmUp()
            setState(.ready)
        } catch {
            setState(.failed(String(describing: error)))
        }
    }


    /// Throwaway inference over 1s of silence to force the ANE JIT.
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

    private func setState(_ state: LoadState) {
        // Progress callbacks arrive off-main; keep loadState + the callback on main.
        DispatchQueue.main.async {
            self.loadState = state
            self.onLoadStateChange?(state)
        }
    }
}

public enum TranscriberError: Error {
    case notLoaded
}
