import Foundation

/// Captures microphone audio as 16 kHz mono Float samples (Whisper's expected format).
public protocol AudioRecording: AnyObject {
    /// Begin capturing. Throws if the engine/mic is unavailable.
    func start() throws
    /// Stop capturing and return the accumulated samples (16 kHz mono).
    func stop() -> [Float]
}

/// Turns 16 kHz mono samples into text. Implementation keeps the model resident + warm.
public protocol Transcribing: AnyObject {
    func transcribe(_ samples: [Float]) async throws -> String
}

/// Puts text into whatever app is focused.
public protocol TextInjecting: AnyObject {
    func inject(_ text: String)
}

/// Whisper's fixed input sample rate.
public let whisperSampleRate: Double = 16_000
