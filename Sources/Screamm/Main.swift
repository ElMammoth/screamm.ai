import AppKit

// Menu-bar-only app: .accessory policy = status item, no dock icon, no main window.
// @MainActor so we can construct the MainActor-isolated AppDelegate.
@main
@MainActor
enum Main {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory)
        app.run()
    }
}
