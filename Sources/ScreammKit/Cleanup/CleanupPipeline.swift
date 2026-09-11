import Foundation

/// Rule-based post-processing for raw Whisper output. Pure functions, no I/O — the
/// cheapest, highest-value tests in the project live here.
///
/// Pipeline (order matters):
///   raw text ──▶ strip fillers ──▶ apply spoken commands ──▶ fix caps/spacing ──▶ out
///
/// Design notes:
///  - Whisper already emits real punctuation, so we do NOT invent a "period" command
///    (avoids the "did they mean the mark or the word" ambiguity).
///  - Spoken commands only fire when they stand alone, so literal "new line" in prose
///    survives.
///  - v0.2 will add a user custom dictionary as a final stage (names/jargon).
public struct CleanupPipeline {

    public init() {}

    /// Standalone filler words to strip (word-boundary, case-insensitive).
    /// Deliberately conservative — only unambiguous fillers.
    static let fillers: Set<String> = ["um", "uh", "er", "erm", "hmm", "uhh", "umm"]

    public func process(_ raw: String, dictionary: CustomDictionary = CustomDictionary()) -> String {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty { return "" }
        text = stripFillers(text)
        text = applySpokenCommands(text)
        text = fixCapitalizationAndSpacing(text)
        text = dictionary.apply(to: text)   // final stage: user replacements (proper nouns/jargon)
        return text
    }

    // MARK: - Stage 1: filler removal

    /// Removes standalone filler words. "drummer" keeps its "um" because we match on
    /// whole words only.
    func stripFillers(_ input: String) -> String {
        let tokens = input.split(separator: " ", omittingEmptySubsequences: true)
        let kept = tokens.filter { token in
            let bare = token.lowercased().trimmingCharacters(in: .punctuationCharacters)
            return !Self.fillers.contains(bare)
        }
        return kept.joined(separator: " ")
    }

    // MARK: - Stage 2: spoken commands

    /// Replaces standalone dictation commands. Only fires when the phrase is bounded by
    /// whitespace/punctuation, so "start a new line here" (prose) is left alone but
    /// "first item. new line. second item" inserts a break.
    func applySpokenCommands(_ input: String) -> String {
        var text = input
        // Order: longer phrases first so "new paragraph" isn't half-matched by "new line".
        let commands: [(phrase: String, replacement: String)] = [
            ("new paragraph", "\n\n"),
            ("new line", "\n")
        ]
        for (phrase, replacement) in commands {
            let escaped = NSRegularExpression.escapedPattern(for: phrase)
            // Fire ONLY at a string bound or next to sentence punctuation (spaces allowed),
            // never between plain words. So "start a new line here" (prose) survives, but a
            // standalone "new line" or "…item. new line. …" inserts a break.
            let pattern = "(?i)(^|[.,!?])[ \\t]*\(escaped)[ \\t]*(?=$|[.,!?])"
            guard let re = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(text.startIndex..., in: text)
            text = re.stringByReplacingMatches(in: text, range: range, withTemplate: "$1\(replacement)")
        }
        return text
    }

    // MARK: - Stage 3: capitalization + spacing

    /// Collapses runs of spaces, trims around newlines, and capitalizes the first letter
    /// of each sentence.
    func fixCapitalizationAndSpacing(_ input: String) -> String {
        // Collapse horizontal whitespace (not newlines) to single spaces.
        var text = input.replacingOccurrences(
            of: "[ \\t]+", with: " ", options: .regularExpression
        )
        // Trim spaces hugging newlines.
        text = text.replacingOccurrences(
            of: " *\\n *", with: "\n", options: .regularExpression
        )
        text = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Capitalize sentence starts: first non-space char, and after . ! ? or newline.
        var result = ""
        var capitalizeNext = true
        for ch in text {
            if capitalizeNext, ch.isLetter {
                result.append(Character(ch.uppercased()))
                capitalizeNext = false
            } else {
                result.append(ch)
                if ch == "." || ch == "!" || ch == "?" || ch == "\n" {
                    capitalizeNext = true
                } else if !ch.isWhitespace {
                    capitalizeNext = false
                }
            }
        }
        return result
    }
}
