import Foundation

/// Cheap speech/silence heuristic used to drop silent clips BEFORE transcription — the root
/// fix for Whisper hallucinating ("Thank you.", "Thanks for watching.") on silence.
///
/// A clip is "likely silent" when both its peak amplitude and RMS are below small thresholds.
/// Requiring BOTH keeps it conservative: a genuinely quiet speaker still peaks well above 0.02,
/// while true silence / room tone sits far below.
public enum AudioAnalysis {

    public static func isLikelySilent(
        _ samples: [Float],
        peakThreshold: Float = 0.02,
        rmsThreshold: Float = 0.008
    ) -> Bool {
        guard !samples.isEmpty else { return true }
        var peak: Float = 0
        var sumSquares: Float = 0
        for s in samples {
            let a = abs(s)
            if a > peak { peak = a }
            sumSquares += s * s
        }
        let rms = (sumSquares / Float(samples.count)).squareRoot()
        return peak < peakThreshold && rms < rmsThreshold
    }
}
