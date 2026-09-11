import Foundation

/// Per-app context settings. v1: which apps get "code mode" (skip auto-capitalization).
/// The frontmost app at dictation time picks the mode.
public struct AppContextSettings: Codable, Equatable, Sendable {

    public struct AppEntry: Codable, Equatable, Sendable, Identifiable {
        public var id: String { bundleID }
        public var bundleID: String
        public var name: String
        public init(bundleID: String, name: String) {
            self.bundleID = bundleID
            self.name = name
        }
    }

    public var smartModeEnabled: Bool
    public var codeApps: [AppEntry]

    public init(smartModeEnabled: Bool = true,
                codeApps: [AppEntry] = AppContextSettings.defaultCodeApps) {
        self.smartModeEnabled = smartModeEnabled
        self.codeApps = codeApps
    }

    /// Sensible defaults — common developer apps.
    public static let defaultCodeApps: [AppEntry] = [
        .init(bundleID: "com.apple.dt.Xcode", name: "Xcode"),
        .init(bundleID: "com.microsoft.VSCode", name: "VS Code"),
        .init(bundleID: "com.apple.Terminal", name: "Terminal"),
        .init(bundleID: "com.googlecode.iterm2", name: "iTerm"),
        .init(bundleID: "dev.zed.Zed", name: "Zed"),
        .init(bundleID: "com.sublimetext.4", name: "Sublime Text"),
        .init(bundleID: "com.panic.Nova", name: "Nova"),
    ]

    /// The cleanup mode for a given frontmost app bundle id.
    public func mode(forBundleID bundleID: String?) -> CleanupMode {
        guard smartModeEnabled, let bundleID else { return .prose }
        return codeApps.contains { $0.bundleID == bundleID } ? .code : .prose
    }
}

/// Seam so the coordinator can ask "what mode for the app I'm dictating into?" — captured at
/// press time (the frontmost app doesn't change: the pill is a non-activating panel).
public protocol CleanupModeProviding: AnyObject {
    func currentCleanupMode() -> CleanupMode
}
