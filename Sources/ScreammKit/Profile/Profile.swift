import Foundation

/// The whole "profile": your first name. Local-only, optional, skippable.
public struct Profile: Codable, Equatable, Sendable {
    public var name: String?

    public init(name: String? = nil) { self.name = name }

    /// Trimmed non-empty name, or nil. Every personalized string goes through this.
    public var displayName: String? {
        guard let trimmed = name?.trimmingCharacters(in: .whitespacesAndNewlines),
              !trimmed.isEmpty else { return nil }
        return trimmed
    }

    /// "Alex's" / "Your" — for possessive copy like "Alex's streak".
    public var possessive: String {
        displayName.map { "\($0)'s" } ?? "Your"
    }

    /// "Nice work, Alex" / "Nice work!" — never a dangling comma.
    public func addressed(_ base: String) -> String {
        displayName.map { "\(base), \($0)" } ?? "\(base)!"
    }
}

/// Local persistence for the profile. Same hardening as the other stores: value-type snapshot,
/// atomic write on a serial queue, corrupt-file backup, missing → empty.
public final class ProfileStore {

    public private(set) var profile: Profile
    private let url: URL
    private let queue = DispatchQueue(label: "ai.screamm.profile")

    public init(url: URL? = nil) {
        self.url = url ?? Self.defaultURL()
        self.profile = Self.load(from: self.url)
    }

    public func update(_ profile: Profile) {
        self.profile = profile
        let snapshot = profile
        queue.async { [url] in try? Self.write(snapshot, to: url) }
    }

    public func flush() {
        let snapshot = profile
        queue.sync { try? Self.write(snapshot, to: url) }
    }

    // MARK: - Files

    static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return base.appendingPathComponent("Screamm/profile.json")
    }

    static func write(_ profile: Profile, to url: URL) throws {
        try FileManager.default.createDirectory(
            at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(profile).write(to: url, options: .atomic)
    }

    static func load(from url: URL) -> Profile {
        guard let bytes = try? Data(contentsOf: url) else { return Profile() }
        do {
            return try JSONDecoder().decode(Profile.self, from: bytes)
        } catch {
            let backup = url.appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: url, to: backup)
            return Profile()
        }
    }
}
