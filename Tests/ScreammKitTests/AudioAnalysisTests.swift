import Testing
import Foundation
@testable import ScreammKit

struct AudioAnalysisTests {
    @Test func emptyIsSilent() {
        #expect(AudioAnalysis.isLikelySilent([]))
    }

    @Test func zerosAreSilent() {
        #expect(AudioAnalysis.isLikelySilent([Float](repeating: 0, count: 16_000)))
    }

    @Test func veryQuietIsSilent() {
        #expect(AudioAnalysis.isLikelySilent([Float](repeating: 0.004, count: 16_000)))
    }

    @Test func loudSignalIsNotSilent() {
        #expect(!AudioAnalysis.isLikelySilent([Float](repeating: 0.3, count: 16_000)))
    }

    @Test func aSinglePeakAboveThresholdCountsAsSpeech() {
        var s = [Float](repeating: 0, count: 16_000)
        // A burst of energy (like a spoken word) → not silent even if mostly quiet.
        for i in 4_000..<6_000 { s[i] = 0.25 }
        #expect(!AudioAnalysis.isLikelySilent(s))
    }
}
