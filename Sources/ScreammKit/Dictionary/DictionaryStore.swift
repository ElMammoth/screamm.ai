import Foundation

/// Local persistence for the custom dictionary. Same hardening as StatsStore: value-type
/// snapshot written atomically on a serial background queue, corrupt-file backup, missing → empty.
public final class DictionaryStore: DictionaryProviding {

    public private(set) var dictionary: CustomDictionary
    private let url: URL
    private let queue = DispatchQueue(label: "ai.screamm.dictionary")

    public init(url: URL? = nil) {
        self.url = url ?? Self.defaultURL()
        self.dictionary = Self.load(from: self.url)
    }

    public func update(_ dictionary: CustomDictionary) {
        self.dictionary = dictionary
        let snapshot = dictionary
        queue.async { [url] in try? Self.write(snapshot, to: url) }
    }

    public func flush() {
        let snapshot = dictionary
        queue.sync { try? Self.write(snapshot, to: url) }
    }

    // MARK: - Files

    static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Screamm/dictionary.json")
    }

    static func write(_ dictionary: CustomDictionary, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoded = try JSONEncoder().encode(dictionary)
        try encoded.write(to: url, options: .atomic)
    }

    static func load(from url: URL) -> CustomDictionary {
        guard let bytes = try? Data(contentsOf: url) else { return CustomDictionary() }
        do {
            return try JSONDecoder().decode(CustomDictionary.self, from: bytes)
        } catch {
            let backup = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return CustomDictionary()
        }
    }
}
