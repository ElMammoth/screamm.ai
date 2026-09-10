import AppKit
import SwiftUI
import ScreammKit

/// The menu bar presence. Left-click opens the stats popover; right-click shows a minimal
/// fallback menu. Status item shows an SF Symbol flame + streak (template image, not emoji,
/// so it tints correctly and doesn't jitter).
@MainActor
final class MenuBarController {

    private let statusItem: NSStatusItem
    private let stats: StatsStore
    private let popover: NSPopover = {
        let p = NSPopover()
        p.behavior = .transient
        return p
    }()
    private var previewHandler: (() -> Void)?

    /// Dev affordance: right-click → "Preview celebration". Wired by AppDelegate.
    func setPreviewCelebration(_ handler: @escaping () -> Void) { previewHandler = handler }

    init(stats: StatsStore) {
        self.stats = stats
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.action = #selector(handleClick)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        refreshStreak()
    }

    // MARK: Status

    func setStatus(_ text: String) {
        statusItem.button?.toolTip = text
    }

    func flashSecureInputNotice() {
        statusItem.button?.toolTip = "Secure input active — press ⌘V to paste"
    }

    func reflectLoadState(_ state: LoadState) {
        switch state {
        case .idle:                  setStatus("Screamm")
        case .downloading(let f):    setStatus("Downloading model… \(Int(f * 100))%")
        case .warming:               setStatus("Warming up…")
        case .ready:                 setStatus("Ready — hold Right ⌘ to dictate")
        case .failed:                setStatus("Model load failed — see Console")
        }
    }

    func update(for state: RecordingState) {
        switch state {
        case .idle:         refreshStreak()
        case .recording:    setGlyph("mic.fill")
        case .transcribing: setGlyph("waveform")
        case .injecting:    setGlyph("checkmark")
        }
    }

    /// Reflect the current streak in the menu bar (called on idle + after each dictation).
    func refreshStreak() {
        guard let button = statusItem.button else { return }
        let streak = stats.data.currentStreak
        if streak > 0 {
            button.image = Self.symbol("flame.fill")
            button.imagePosition = .imageLeading
            button.attributedTitle = NSAttributedString(
                string: " \(streak)",
                attributes: [.font: NSFont.monospacedDigitSystemFont(ofSize: 13, weight: .semibold)])
        } else {
            button.image = Self.symbol("mic.fill")
            button.imagePosition = .imageOnly
            button.title = ""
        }
    }

    // MARK: Clicks

    @objc private func handleClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showContextMenu()
        } else {
            togglePopover()
        }
    }

    private func togglePopover() {
        guard let button = statusItem.button else { return }
        if popover.isShown {
            popover.performClose(nil)
            return
        }
        // Accessory apps must activate or the popover's SwiftUI controls get no events.
        NSApp.activate(ignoringOtherApps: true)
        let host = NSHostingController(
            rootView: StatsPanel(data: stats.data, onQuit: { NSApp.terminate(nil) }))
        // Size the popover to the SwiftUI content — without this the popover can be
        // mis-sized and clip above the top of the screen.
        host.sizingOptions = [.preferredContentSize]
        popover.contentViewController = host
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    @objc private func previewCelebration() { previewHandler?() }

    private func showContextMenu() {
        let menu = NSMenu()
        if previewHandler != nil {
            let preview = NSMenuItem(
                title: "Preview celebration", action: #selector(previewCelebration), keyEquivalent: "")
            preview.target = self
            menu.addItem(preview)
            menu.addItem(.separator())
        }
        let quit = NSMenuItem(
            title: "Quit Screamm", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        quit.target = NSApp
        menu.addItem(quit)
        if let button = statusItem.button {
            menu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height + 4), in: button)
        }
    }

    private func setGlyph(_ name: String) {
        guard let button = statusItem.button else { return }
        button.image = Self.symbol(name)
        button.imagePosition = .imageOnly
        button.title = ""
    }

    private static func symbol(_ name: String) -> NSImage? {
        let image = NSImage(systemSymbolName: name, accessibilityDescription: name)
        image?.isTemplate = true
        return image
    }
}
