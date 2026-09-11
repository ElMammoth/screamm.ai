import Foundation

/// Local persistence for per-app context settings. Same hardening as the other stores:
/// atomic background write, corrupt-file backup, missing → defaults.
public final class AppContextStore {

    public private(set) var settings: AppContextSettings
    private let url: URL
    private let queue = DispatchQueue(label: "ai.screamm.context")

    public init(url: URL? = nil) {
        self.url = url ?? Self.defaultURL()
        self.settings = Self.load(from: self.url)
    }

    public func update(_ settings: AppContextSettings) {
        self.settings = settings
        let snapshot = settings
        queue.async { [url] in try? Self.write(snapshot, to: url) }
    }

    public func mode(forBundleID bundleID: String?) -> CleanupMode {
        settings.mode(forBundleID: bundleID)
    }

    public func flush() {
        let snapshot = settings
        queue.sync { try? Self.write(snapshot, to: url) }
    }

    // MARK: - Files

    static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Screamm/context.json")
    }

    static func write(_ settings: AppContextSettings, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(settings).write(to: url, options: .atomic)
    }

    static func load(from url: URL) -> AppContextSettings {
        guard let bytes = try? Data(contentsOf: url) else { return AppContextSettings() }
        do {
            return try JSONDecoder().decode(AppContextSettings.self, from: bytes)
        } catch {
            let backup = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return AppContextSettings()
        }
    }
}
