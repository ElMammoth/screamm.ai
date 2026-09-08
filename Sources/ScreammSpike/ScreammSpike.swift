import Foundation
import WhisperKit

// ─────────────────────────────────────────────────────────────────────────────
// Screamm.ai — ENGINE SPIKE (throwaway, delete once it answers the question)
//
// The go/no-go gate from the design doc:
//   "warm decode of a ~10s clip is sub-2s on this Mac" → the whole product is viable.
//
// Flow:
//   load model (cold)  →  warm-up inference (discarded)  →  timed transcribe (warm)
//
// Usage:
//   swift run ScreammSpike <audio-file>            # transcribe + time it
//   swift run ScreammSpike --list-models           # print valid model identifiers
//   swift run ScreammSpike <audio-file> --model <id>
//
// No audio file yet? Generate one with macOS `say`:
//   say -o sample.aiff "Testing Screamm dot A I. One two three, this is a warm decode test."
//   swift run ScreammSpike sample.aiff
// ─────────────────────────────────────────────────────────────────────────────

@main
struct ScreammSpike {
    // Turbo is the default we care about (fast decode, ~same accuracy as large-v3).
    // If this identifier is wrong for your installed WhisperKit, run --list-models.
    static let defaultModel = "large-v3-v20240930_turbo"

    static func main() async {
        let args = Array(CommandLine.arguments.dropFirst())

        if args.contains("--list-models") {
            await listModels()
            return
        }

        guard let audioPath = args.first(where: { !$0.hasPrefix("--") }) else {
            printUsage()
            exit(2)
        }
        guard FileManager.default.fileExists(atPath: audioPath) else {
            fail("audio file not found: \(audioPath)")
        }

        let model = value(for: "--model", in: args) ?? defaultModel

        do {
            // 1) COLD: load + compile the model onto the Neural Engine.
            print("→ loading model '\(model)' (first run downloads it, ~600MB-1.5GB)…")
            let loadStart = Date()
            let config = WhisperKitConfig(model: model)
            let pipe = try await WhisperKit(config)
            let loadSecs = Date().timeIntervalSince(loadStart)
            print(String(format: "  cold load: %.2fs", loadSecs))

            // 2) WARM-UP: first inference re-JITs the ANE. Discard its timing.
            //    (Design doc: "resident" isn't enough — CoreML re-JITs after idle.)
            print("→ warm-up inference (discarded)…")
            _ = try await pipe.transcribe(audioPath: audioPath)

            // 3) WARM: this is the number that decides the project.
            print("→ timed warm decode…")
            let warmStart = Date()
            let results = try await pipe.transcribe(audioPath: audioPath)
            let warmSecs = Date().timeIntervalSince(warmStart)

            let text = results.map { $0.text }.joined(separator: " ")
                .trimmingCharacters(in: .whitespacesAndNewlines)

            print("\n─── RESULT ───────────────────────────────")
            print("text: \(text.isEmpty ? "(empty — silence or hallucination-suppressed)" : text)")
            print(String(format: "cold load:   %.2fs", loadSecs))
            print(String(format: "warm decode: %.2fs   ← the go/no-go number", warmSecs))
            print("──────────────────────────────────────────")
            if warmSecs <= 2.0 {
                print("✅ GO — warm decode ≤ 2s. Local turbo is fast enough. Build the app.")
            } else {
                print("⚠️  warm decode > 2s. Try a smaller model or investigate before committing to turbo-only.")
            }
        } catch {
            fail("transcription failed: \(error)\n\nIf this is a model-name error, run: swift run ScreammSpike --list-models")
        }
    }

    static func listModels() async {
        do {
            let models = try await WhisperKit.fetchAvailableModels()
            print("Available WhisperKit models:")
            for m in models { print("  \(m)") }
        } catch {
            fail("could not fetch model list: \(error)")
        }
    }

    static func value(for flag: String, in args: [String]) -> String? {
        guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
        return args[i + 1]
    }

    static func printUsage() {
        print("""
        Screamm engine spike
          swift run ScreammSpike <audio-file> [--model <id>]
          swift run ScreammSpike --list-models

        No audio yet?
          say -o sample.aiff "Testing Screamm. One two three."
          swift run ScreammSpike sample.aiff
        """)
    }

    static func fail(_ msg: String) -> Never {
        FileHandle.standardError.write(Data(("error: " + msg + "\n").utf8))
        exit(1)
    }
}
