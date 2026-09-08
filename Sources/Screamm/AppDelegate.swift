import AppKit
import ScreammKit

/// Wires ScreammKit together and owns the object graph. Menu-bar-only app (no dock icon).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let recorder = AudioRecorder()
    private let transcriber = WhisperKitTranscriber()
    private let injector = ClipboardInjector()
    private let hotkey = HotkeyManager()

    private let overlay = OverlayController()
    private var coordinator: RecordingCoordinator?
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuBar = MenuBarController()
        self.menuBar = menuBar

        let coordinator = RecordingCoordinator(
            recorder: recorder,
            transcriber: transcriber,
            injector: injector
        )
        self.coordinator = coordinator

        coordinator.onStateChange = { [weak menuBar, overlay] state in
            menuBar?.update(for: state)
            overlay.update(for: state)
        }
        coordinator.onError = { error in
            NSLog("Screamm error: \(error)")
        }
        injector.onSecureInputBlocked = { [weak menuBar] _ in
            menuBar?.flashSecureInputNotice()
        }

        // Live audio levels drive the waveform overlay.
        recorder.onLevel = { [overlay] level in
            overlay.pushLevel(level)
        }

        hotkey.onPress = { [weak coordinator] in coordinator?.handlePress() }
        hotkey.onRelease = { [weak coordinator] in coordinator?.handleRelease() }

        Task { await bootstrap() }
    }

    /// Request permissions, start the hotkey, load + warm the model.
    private func bootstrap() async {
        if Permissions.microphoneStatus != .authorized {
            _ = await Permissions.requestMicrophone()
        }
        if !Permissions.isAccessibilityTrusted {
            Permissions.promptAccessibility()
        }

        hotkey.start()

        menuBar?.setStatus("Loading model…")
        do {
            try await transcriber.load()
            menuBar?.setStatus("Ready — hold Right ⌘ to dictate")
        } catch {
            menuBar?.setStatus("Model load failed — see Console")
            NSLog("Screamm model load failed: \(error)")
        }
    }
}
