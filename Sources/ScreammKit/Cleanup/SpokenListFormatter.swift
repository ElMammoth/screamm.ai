import Foundation

/// Turns spoken structure into real lists — "say a list, get a list".
///
/// Two mechanisms, both conservative so ordinary prose is never mangled:
///
/// 1. **Explicit** — a leading directive ("numbered list", "bullet list", "make a list") and/or
///    "new bullet" / "next item" separators. Needs 2+ items.
/// 2. **Auto-detect** — 2+ **consecutive** ordinals starting at "first"
///    ("first … second … third …"), each followed by real content. A lone
///    "first, I went to the store" stays prose (one ordinal), and a gap
///    ("first … third …") is rejected.
///
/// "end list" terminates the list; anything after it stays prose.
public struct SpokenListFormatter {

    enum Style { case bullet, numbered }

    static let ordinals = ["first", "second", "third", "fourth", "fifth",
                           "sixth", "seventh", "eighth", "ninth", "tenth"]

    public init() {}

    /// - Parameter capitalizeItems: prose mode capitalizes each item; code mode leaves it alone.
    public func format(_ input: String, capitalizeItems: Bool = true) -> String {
        let (rawBody, suffix) = splitOnEndList(input)
        var body = rawBody
        let forced = stripDirective(&body)

        var list: String?
        let parts = splitOnSeparators(body)
        if parts.count >= 2 {
            list = render(parts, style: forced ?? .bullet, capitalizeItems: capitalizeItems)
        } else if let (preamble, items) = ordinalItems(body) {
            let rendered = render(items, style: forced ?? .numbered, capitalizeItems: capitalizeItems)
            list = preamble.isEmpty ? rendered : preamble + "\n" + rendered
        }

        guard let list else { return input }
        return suffix.isEmpty ? list : list + "\n\n" + suffix
    }

    // MARK: - Pieces

    /// "end list" splits the utterance into the list body and trailing prose.
    private func splitOnEndList(_ text: String) -> (String, String) {
        guard let re = try? NSRegularExpression(pattern: "(?i)\\bend list\\b"),
              let m = re.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
              let r = Range(m.range, in: text) else { return (text, "") }
        let body = String(text[text.startIndex..<r.lowerBound])
        let suffix = clean(String(text[r.upperBound...]))
        return (body, suffix)
    }

    /// Strips a leading "numbered list" / "bullet list" / "make a list" and returns the style.
    private func stripDirective(_ body: inout String) -> Style? {
        let pattern = "(?i)^\\s*(numbered list|bulleted list|bullet list|make a list)\\b[,:]?\\s*"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = body as NSString
        guard let m = re.firstMatch(in: body, range: NSRange(location: 0, length: ns.length)) else { return nil }
        let word = ns.substring(with: m.range(at: 1)).lowercased()
        body = ns.substring(from: m.range.location + m.range.length)
        return word.hasPrefix("numbered") ? .numbered : .bullet
    }

    /// Splits on spoken item separators.
    private func splitOnSeparators(_ text: String) -> [String] {
        guard let re = try? NSRegularExpression(
            pattern: "(?i)\\b(?:new bullet|next item|new item)\\b") else { return [] }
        let ns = text as NSString
        let matches = re.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard !matches.isEmpty else { return [] }

        var parts: [String] = []
        var location = 0
        for m in matches {
            parts.append(ns.substring(with: NSRange(location: location, length: m.range.location - location)))
            location = m.range.location + m.range.length
        }
        parts.append(ns.substring(from: location))
        let cleaned = parts.map(clean).filter { !$0.isEmpty }
        return cleaned.count >= 2 ? cleaned : []
    }

    /// Finds a run of consecutive ordinals starting at "first", each with real content.
    private func ordinalItems(_ text: String) -> (preamble: String, items: [String])? {
        let pattern = "(?i)\\b(" + Self.ordinals.joined(separator: "|") + ")\\b[,:]?\\s+"
        guard let re = try? NSRegularExpression(pattern: pattern) else { return nil }
        let ns = text as NSString
        let matches = re.matches(in: text, range: NSRange(location: 0, length: ns.length))
        guard matches.count >= 2 else { return nil }

        // Must be first, second, third… with no gaps and no repeats.
        var expected = 0
        var marks: [(markerStart: Int, contentStart: Int)] = []
        for m in matches {
            let word = ns.substring(with: m.range(at: 1)).lowercased()
            guard let index = Self.ordinals.firstIndex(of: word), index == expected else { return nil }
            expected += 1
            marks.append((m.range.location, m.range.location + m.range.length))
        }

        let preamble = clean(ns.substring(to: marks[0].markerStart))
        var items: [String] = []
        for (i, mark) in marks.enumerated() {
            let end = (i + 1 < marks.count) ? marks[i + 1].markerStart : ns.length
            items.append(clean(ns.substring(with: NSRange(location: mark.contentStart,
                                                          length: end - mark.contentStart))))
        }
        // Every item needs content — protects "I was first and she was second".
        guard !items.contains(where: { $0.isEmpty }) else { return nil }
        return (preamble, items)
    }

    private func render(_ items: [String], style: Style, capitalizeItems: Bool) -> String {
        items.enumerated().map { index, item in
            let text = capitalizeItems ? capitalizeFirst(item) : item
            return style == .numbered ? "\(index + 1). \(text)" : "- \(text)"
        }.joined(separator: "\n")
    }

    private func capitalizeFirst(_ s: String) -> String {
        guard let f = s.first else { return s }
        return String(f).uppercased() + s.dropFirst()
    }

    /// Trim whitespace and strip separator punctuation that bled into an item.
    private func clean(_ s: String) -> String {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        while let f = t.first, ",:;-•.".contains(f) {
            t.removeFirst()
            t = t.trimmingCharacters(in: .whitespaces)
        }
        // Drop the sentence period that ends an item ("Buy milk." → "Buy milk").
        // Safe for things like "v0.3" / "example.com" (they don't END on the dot).
        while let l = t.last, ",;.".contains(l) {
            t.removeLast()
            t = t.trimmingCharacters(in: .whitespaces)
        }
        return t
    }
}
