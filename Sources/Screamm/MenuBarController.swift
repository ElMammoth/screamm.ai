import AppKit
import ScreammKit

/// The menu bar presence. v0.1 UI is just the status icon + a status line; the floating
/// pill overlay is v0.2.
@MainActor
final class MenuBarController {

    private let statusItem: NSStatusItem
    private let statusLine: NSMenuItem

    init() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = Glyph.idle

        let menu = NSMenu()
        statusLine = NSMenuItem(title: "Starting…", action: nil, keyEquivalent: "")
        statusLine.isEnabled = false
        menu.addItem(statusLine)
        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit Screamm",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        quit.target = NSApp
        menu.addItem(quit)

        statusItem.menu = menu
    }

    func setStatus(_ text: String) {
        statusLine.title = text
    }

    func update(for state: RecordingState) {
        switch state {
        case .idle:         statusItem.button?.title = Glyph.idle
        case .recording:    statusItem.button?.title = Glyph.recording
        case .transcribing: statusItem.button?.title = Glyph.transcribing
        case .injecting:    statusItem.button?.title = Glyph.injecting
        }
    }

    func flashSecureInputNotice() {
        setStatus("Secure input active — press ⌘V to paste")
    }

    private enum Glyph {
        static let idle = "🎙️"
        static let recording = "🔴"
        static let transcribing = "✍️"
        static let injecting = "📋"
    }
}
