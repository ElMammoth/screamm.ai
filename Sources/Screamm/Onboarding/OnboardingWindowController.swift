import AppKit
import SwiftUI

/// Hosts the onboarding SwiftUI flow in a real window. A menu-bar-only (.accessory) app can't
/// make a window key or accept keyboard focus, so we flip to .regular while onboarding is open
/// and back to .accessory when it finishes (eng review).
@MainActor
final class OnboardingWindowController {

    let model = OnboardingModel()
    private var window: NSWindow?

    /// Called after onboarding finishes/skips (set `onboardingCompleted`, resume normal launch).
    var onFinished: () -> Void = {}

    func show() {
        model.onFinish = { [weak self] in self?.finish() }

        let host = NSHostingController(rootView: OnboardingView(model: model))
        let window = NSWindow(contentViewController: host)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.setContentSize(NSSize(width: 460, height: 560))
        window.center()
        window.isReleasedWhenClosed = false
        self.window = window

        NSApp.setActivationPolicy(.regular)       // so the window can become key + take focus
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func finish() {
        window?.close()
        window = nil
        NSApp.setActivationPolicy(.accessory)     // back to menu-bar-only
        onFinished()
    }
}
