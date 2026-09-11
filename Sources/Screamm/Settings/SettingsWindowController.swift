import AppKit
import SwiftUI
import ScreammKit

/// Hosts the dictionary editor. Like onboarding, flips to `.regular` so the window can take
/// keyboard focus (text fields), back to `.accessory` on close. Saves on close too, so edits
/// aren't lost if the user clicks the red button instead of Done.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {

    private let store: DictionaryStore
    private var window: NSWindow?
    private var model: DictionaryEditModel?

    init(store: DictionaryStore) {
        self.store = store
        super.init()
    }

    func show() {
        if let window {
            bringToFront(window)
            return
        }
        let model = DictionaryEditModel(store: store)
        self.model = model
        let host = NSHostingController(
            rootView: DictionarySettingsView(model: model, onDone: { [weak self] in self?.window?.close() }))
        let window = NSWindow(contentViewController: host)
        window.title = "Screamm — Dictionary"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 480, height: 420))
        window.center()
        window.isReleasedWhenClosed = false
        window.delegate = self
        self.window = window
        bringToFront(window)
    }

    private func bringToFront(_ window: NSWindow) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    func windowWillClose(_ notification: Notification) {
        model?.save()
        model = nil
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
