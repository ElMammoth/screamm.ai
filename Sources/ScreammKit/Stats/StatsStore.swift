import Foundation

/// The coordinator records a successful dictation through this seam (testable with a fake).
public protocol StatsRecording: AnyObject {
    @discardableResult
    func recordDictation(wordCount: Int, at date: Date) -> Milestone?
}

/// Local-only stats persistence. Holds an in-memory `StatsData` (a value type), and writes
/// snapshots atomically on a serial background queue so the main thread never blocks on disk.
///
/// Hardening (eng review):
///  - snapshot the value type on the caller thread, hand the copy to a SERIAL queue
///  - `Data.write(.atomic)` = temp + rename; create the directory first
///  - `flush()` writes synchronously for `applicationWillTerminate`
///  - corrupt file → back up to `stats.json.bak` and start empty (never crash)
public final class StatsStore: StatsRecording {

    public private(set) var data: StatsData
    private let url: URL
    private let calendar: Calendar
    private let queue = DispatchQueue(label: "ai.screamm.stats")

    public init(url: URL? = nil, calendar: Calendar = .current) {
        self.calendar = calendar
        self.url = url ?? Self.defaultURL()
        self.data = Self.load(from: self.url)
    }

    @discardableResult
    public func recordDictation(wordCount: Int, at date: Date = Date()) -> Milestone? {
        let milestone = data.record(wordCount: wordCount, at: date, calendar: calendar)
        persist()
        return milestone
    }

    public func reset() {
        data = StatsData()
        persist()
    }

    /// Synchronous flush — call from `applicationWillTerminate` so a quit mid-write can't lose data.
    public func flush() {
        let snapshot = data
        queue.sync { try? Self.write(snapshot, to: url) }
    }

    private func persist() {
        let snapshot = data
        queue.async { [url] in try? Self.write(snapshot, to: url) }
    }

    // MARK: - Files

    static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Screamm/stats.json")
    }

    static func write(_ data: StatsData, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let encoded = try JSONEncoder().encode(data)
        try encoded.write(to: url, options: .atomic)
    }

    static func load(from url: URL) -> StatsData {
        guard let bytes = try? Data(contentsOf: url) else { return StatsData() }
        do {
            return try JSONDecoder().decode(StatsData.self, from: bytes)
        } catch {
            // Corrupt: preserve the bad file for forensics, start fresh.
            let backup = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return StatsData()
        }
    }
}
