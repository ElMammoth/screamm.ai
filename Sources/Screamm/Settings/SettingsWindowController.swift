import AppKit
import SwiftUI
import ScreammKit

/// Hosts the settings tabs (dictionary + per-app code mode). Like onboarding, flips to
/// `.regular` so text fields take focus, back to `.accessory` on close. Saves both models on
/// close so edits aren't lost if the user clicks the red button instead of Done.
@MainActor
final class SettingsWindowController: NSObject, NSWindowDelegate {

    private let dictionaryStore: DictionaryStore
    private let contextStore: AppContextStore
    private let profileStore: ProfileStore
    private var window: NSWindow?
    private var dictionaryModel: DictionaryEditModel?
    private var codeModeModel: CodeModeEditModel?
    private var profileModel: ProfileEditModel?

    /// Called after a save, so live surfaces (the stats card) pick the new name up.
    var onProfileChanged: () -> Void = {}

    init(dictionaryStore: DictionaryStore, contextStore: AppContextStore, profileStore: ProfileStore) {
        self.dictionaryStore = dictionaryStore
        self.contextStore = contextStore
        self.profileStore = profileStore
        super.init()
    }

    func show() {
        if let window {
            bringToFront(window)
            return
        }
        let dictionaryModel = DictionaryEditModel(store: dictionaryStore)
        let codeModeModel = CodeModeEditModel(store: contextStore)
        let profileModel = ProfileEditModel(store: profileStore)
        self.dictionaryModel = dictionaryModel
        self.codeModeModel = codeModeModel
        self.profileModel = profileModel

        let host = NSHostingController(rootView: SettingsView(
            dictionary: dictionaryModel,
            codeMode: codeModeModel,
            profile: profileModel,
            onDone: { [weak self] in self?.window?.close() }))
        let window = NSWindow(contentViewController: host)
        window.title = "Screamm — Settings"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 500, height: 470))
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
        dictionaryModel?.save()
        codeModeModel?.save()
        profileModel?.save()
        onProfileChanged()
        dictionaryModel = nil
        codeModeModel = nil
        profileModel = nil
        window = nil
        NSApp.setActivationPolicy(.accessory)
    }
}
