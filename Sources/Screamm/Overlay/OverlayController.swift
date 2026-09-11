import AppKit
import SwiftUI
import ScreammKit

/// The floating waveform overlay, pinned to the bottom-center of the screen. A borderless,
/// non-activating, click-through panel that shows while recording/transcribing and hides
/// when idle. This is the "pill" from the design doc, positioned bottom-center (Wispr-style)
/// rather than at the cursor.
@MainActor
final class OverlayController {

    private let model = WaveformModel()
    private var panel: NSPanel?

    /// Feed a live audio level (0...1) into the waveform.
    func pushLevel(_ level: Float) {
        model.push(CGFloat(level))
    }

    /// Flash the green ✓ micro-reward (shown briefly before the pill pops out on idle).
    func flashSuccess() {
        model.success = true
    }

    /// Show/hide + style the overlay based on the recording state.
    func update(for state: RecordingState) {
        switch state {
        case .recording:
            model.isTranscribing = false
            show()
        case .transcribing:
            model.isTranscribing = true // dim the bars while we think
        case .injecting:
            break                        // stay up until idle
        case .idle:
            hide()
        }
    }

    // MARK: - Panel lifecycle

    private func show() {
        let panel = panel ?? makePanel()
        self.panel = panel
        reposition(panel)
        panel.orderFrontRegardless()
        // SwiftUI drives the spring pop-in.
        model.appear = true
    }

    private func hide() {
        model.appear = false
        // Let the spring pop-out finish before we pull the panel offscreen.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self, self.model.appear == false else { return }
            self.panel?.orderOut(nil)
            self.model.reset()
        }
    }

    private func makePanel() -> NSPanel {
        let hosting = NSHostingView(rootView: WaveformView(model: model))
        hosting.layout()
        let size = hosting.fittingSize

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false // we draw a branded orange glow in SwiftUI instead
        panel.level = .statusBar
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.ignoresMouseEvents = true          // click-through
        panel.hidesOnDeactivate = false
        panel.contentView = hosting
        return panel
    }

    /// Bottom-center of the active screen, floating just above the Dock.
    private func reposition(_ panel: NSPanel) {
        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        let size = panel.frame.size
        let x = visible.midX - size.width / 2
        let y = visible.minY + 24     // low, just above the Dock / bottom edge
        panel.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
