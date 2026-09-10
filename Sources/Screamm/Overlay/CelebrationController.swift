import AppKit
import SwiftUI
import ScreammKit

/// Shows a milestone celebration near the pill (bottom-center). Uses its OWN
/// `.nonactivatingPanel` — separate from the waveform overlay — so the confetti never steals
/// keyboard focus from whatever the user is typing in (eng review). Click-through, auto-dismiss.
@MainActor
final class CelebrationController {

    private var panel: NSPanel?

    func celebrate(_ milestone: Milestone) {
        panel?.orderOut(nil)

        let host = NSHostingView(rootView: CelebrationView(milestone: milestone))
        host.frame = NSRect(x: 0, y: 0, width: 320, height: 220)

        let panel = NSPanel(
            contentRect: host.frame,
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered, defer: false)
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true          // click-through, never focus-steals
        panel.contentView = host
        reposition(panel)
        panel.orderFrontRegardless()
        self.panel = panel

        // Auto-dismiss after the burst.
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self, weak panel] in
            panel?.orderOut(nil)
            if self?.panel === panel { self?.panel = nil }
        }
    }

    /// Bottom-center, just above where the waveform pill sits.
    private func reposition(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        panel.setFrameOrigin(NSPoint(x: visible.midX - size.width / 2,
                                     y: visible.minY + 120))
    }
}
