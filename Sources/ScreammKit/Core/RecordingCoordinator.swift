import Foundation

/// Orchestrates one dictation: press → record → release → transcribe → cleanup → inject.
/// Owns the `RecordingState` machine and enforces the no-overlap guard.
///
/// Wiring (all dependencies are protocols, so this is unit-testable with fakes):
///
///   HotkeyManager ──press/release──▶ RecordingCoordinator
///                                        │
///                     ┌──────────────────┼───────────────────┐
///                     ▼                  ▼                    ▼
///                AudioRecording     Transcribing        TextInjecting
///                                        │
///                                   CleanupPipeline
///
@MainActor
public final class RecordingCoordinator {

    public private(set) var state: RecordingState = .idle {
        didSet { if oldValue != state { onStateChange?(state) } }
    }

    /// Observed by the menu bar to reflect status. Called on the main actor.
    public var onStateChange: ((RecordingState) -> Void)?
    /// Surfaced to the user (e.g. a notification) when we can't inject or transcribe.
    public var onError: ((Error) -> Void)?
    /// Fired after a successful dictation with the injected word count (drives the micro-reward).
    public var onSuccess: ((Int) -> Void)?
    /// Fired when a dictation crosses a stats milestone (drives celebrations).
    public var onMilestone: ((Milestone) -> Void)?

    private let recorder: AudioRecording
    private let transcriber: Transcribing
    private let injector: TextInjecting
    private let cleanup: CleanupPipeline
    private let stats: StatsRecording?
    private let dictionary: DictionaryProviding?
    private let minDurationSeconds: Double

    public init(
        recorder: AudioRecording,
        transcriber: Transcribing,
        injector: TextInjecting,
        cleanup: CleanupPipeline = CleanupPipeline(),
        stats: StatsRecording? = nil,
        dictionary: DictionaryProviding? = nil,
        minDurationSeconds: Double = 0.35
    ) {
        self.recorder = recorder
        self.transcriber = transcriber
        self.injector = injector
        self.cleanup = cleanup
        self.stats = stats
        self.dictionary = dictionary
        self.minDurationSeconds = minDurationSeconds
    }

    /// Hotkey pressed. Starts recording only from idle (the concurrency guard).
    public func handlePress() {
        guard state.canStartRecording else { return }
        do {
            try recorder.start()
            state = .recording
        } catch {
            state = .idle
            onError?(error)
        }
    }

    /// Hotkey released. Stops recording and runs the transcribe→cleanup→inject chain.
    /// No-op unless we were actually recording (covers a lost/duplicate release).
    public func handleRelease() {
        guard state == .recording else { return }
        let samples = recorder.stop()

        // Min-duration gate: an accidental tap produces almost no audio → discard,
        // never paste. (samples.count / 16000 = seconds.)
        let seconds = Double(samples.count) / whisperSampleRate
        guard seconds >= minDurationSeconds else {
            state = .idle
            return
        }

        state = .transcribing
        Task { [weak self] in
            await self?.runTranscription(samples)
        }
    }

    private func runTranscription(_ samples: [Float]) async {
        do {
            let raw = try await transcriber.transcribe(samples)
            let cleaned = cleanup.process(raw, dictionary: dictionary?.dictionary ?? CustomDictionary())

            // Suppress empty / hallucinated-on-silence output — never paste noise.
            guard !cleaned.isEmpty else {
                state = .idle
                return
            }

            state = .injecting
            injector.inject(cleaned)

            let wordCount = cleaned.split(whereSeparator: { $0.isWhitespace }).count
            onSuccess?(wordCount)
            if let milestone = stats?.recordDictation(wordCount: wordCount, at: Date()) {
                onMilestone?(milestone)
            }

            state = .idle
        } catch {
            state = .idle
            onError?(error)
        }
    }
}
