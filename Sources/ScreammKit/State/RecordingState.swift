import Foundation

/// The spine of the app. Every dictation moves through these states, and the machine
/// guarantees sessions never overlap.
///
///   idle ──press──▶ recording ──release──▶ transcribing ──▶ injecting ──▶ idle
///     ▲                                                                     │
///     └─────────────────────────── (too-short release discards) ───────────┘
///
/// A press that arrives while not `idle` is ignored (the concurrency guard).
public enum RecordingState: Equatable, Sendable {
    case idle
    case recording
    case transcribing
    case injecting

    /// Only from `idle` may a new recording begin.
    public var canStartRecording: Bool { self == .idle }
}
