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
        reposition(panel)              // origin = resting position (near the bottom)
        model.appear = true
        let target = panel.frame.origin

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.alphaValue = 1
            panel.orderFrontRegardless()
            return
        }
        // Smoothly slide up from below its place + fade in.
        panel.setFrameOrigin(NSPoint(x: target.x, y: target.y - 46))
        panel.alphaValue = 0
        panel.orderFrontRegardless()
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.32
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrameOrigin(target)
            panel.animator().alphaValue = 1
        }
    }

    private func hide() {
        guard let panel else { return }
        model.appear = false

        if NSWorkspace.shared.accessibilityDisplayShouldReduceMotion {
            panel.orderOut(nil)
            model.reset()
            return
        }
        let origin = panel.frame.origin
        NSAnimationContext.runAnimationGroup({ ctx in
            ctx.duration = 0.22
            ctx.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().alphaValue = 0
            panel.animator().setFrameOrigin(NSPoint(x: origin.x, y: origin.y - 30))
        }, completionHandler: { [weak self] in
            // AppKit calls this back on a nonisolated context, but `model` is @MainActor.
            // Hop explicitly rather than relying on it happening to run on the main thread.
            MainActor.assumeIsolated {
                panel.orderOut(nil)
                self?.model.reset()
            }
        })
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
