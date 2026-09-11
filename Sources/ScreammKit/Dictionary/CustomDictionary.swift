import Foundation

/// A user-editable set of replacements applied as the FINAL cleanup stage — the fix for
/// proper-noun mistranscriptions ("screen" → "Screamm", "scram" → "Screamm").
///
/// Matching is whole-word / whole-phrase and case-insensitive; the replacement keeps its own
/// casing (so "Screamm.ai" stays capitalized). `\b` boundaries mean "screenshot" is NOT touched
/// by a "screen" rule.
public struct CustomDictionary: Codable, Equatable, Sendable {

    public struct Entry: Codable, Equatable, Sendable, Identifiable {
        public var id: UUID
        public var from: String
        public var to: String
        public init(id: UUID = UUID(), from: String, to: String) {
            self.id = id; self.from = from; self.to = to
        }
    }

    public var entries: [Entry]

    public init(entries: [Entry] = []) { self.entries = entries }

    public func apply(to text: String) -> String {
        var result = text
        for entry in entries {
            let from = entry.from.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !from.isEmpty else { continue }
            let pattern = "(?i)\\b\(NSRegularExpression.escapedPattern(for: from))\\b"
            guard let re = try? NSRegularExpression(pattern: pattern) else { continue }
            let range = NSRange(result.startIndex..., in: result)
            let template = NSRegularExpression.escapedTemplate(for: entry.to)
            result = re.stringByReplacingMatches(in: result, range: range, withTemplate: template)
        }
        return result
    }
}

/// Seam so the coordinator can read the current dictionary at transcription time (it changes
/// when the user edits it). Mirrors `Transcribing`/`TextInjecting`/`StatsRecording`.
public protocol DictionaryProviding: AnyObject {
    var dictionary: CustomDictionary { get }
}
