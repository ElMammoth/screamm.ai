import AppKit
import SwiftUI

/// A popover-like panel WITHOUT the system arrow (which caused the background-color mismatch).
/// A borderless, non-activating, transparent panel positioned under the status item, dismissed
/// on any outside click. The SwiftUI content draws its own rounded card, so the window shadow
/// follows the rounded shape.
@MainActor
final class StatsWindowController {

    private var panel: NSPanel?
    private var monitor: Any?

    var isShown: Bool { panel != nil }

    func toggle(relativeTo button: NSStatusBarButton, view: @autoclosure () -> NSView) {
        if panel != nil { close() } else { open(relativeTo: button, content: view()) }
    }

    func close() {
        if let monitor { NSEvent.removeMonitor(monitor); self.monitor = nil }
        panel?.orderOut(nil)
        panel = nil
    }

    private func open(relativeTo button: NSStatusBarButton, content: NSView) {
        content.layoutSubtreeIfNeeded()
        let size = content.fittingSize
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = content
        position(panel, under: button, size: size)
        panel.orderFrontRegardless()
        self.panel = panel

        // Dismiss on any click outside our app (clicks inside the panel are local events).
        monitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.close()
        }
    }

    private func position(_ panel: NSPanel, under button: NSStatusBarButton, size: NSSize) {
        guard let buttonWindow = button.window else { return }
        let rectInWindow = button.convert(button.bounds, to: nil)
        let onScreen = buttonWindow.convertToScreen(rectInWindow)
        var x = onScreen.midX - size.width / 2
        let y = onScreen.minY - size.height - 6
        // Keep it on screen horizontally.
        if let vf = (button.window?.screen ?? NSScreen.main)?.visibleFrame {
            x = min(max(x, vf.minX + 8), vf.maxX - size.width - 8)
        }
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
