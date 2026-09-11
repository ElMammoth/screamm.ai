import AppKit
import ScreammKit

/// Resolves the cleanup mode from the actual frontmost app. Lives in the app layer because it
/// touches `NSWorkspace`; the pure mode logic + persistence are in `AppContextStore` (ScreammKit).
final class SystemContextResolver: CleanupModeProviding {
    private let store: AppContextStore
    init(store: AppContextStore) { self.store = store }

    func currentCleanupMode() -> CleanupMode {
        let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        return store.mode(forBundleID: bundleID)
    }
}
