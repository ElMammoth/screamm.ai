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
    private let stats = StatsStore()
    private var coordinator: RecordingCoordinator?
    private var menuBar: MenuBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuBar = MenuBarController(stats: stats)
        self.menuBar = menuBar

        let coordinator = RecordingCoordinator(
            recorder: recorder,
            transcriber: transcriber,
            injector: injector,
            stats: stats
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

        // Success micro-reward (green ✓ on the pill). Milestones celebrated in a later phase.
        coordinator.onSuccess = { [overlay] _ in
            overlay.flashSuccess()
        }
        coordinator.onMilestone = { milestone in
            NSLog("Screamm milestone reached: \(milestone.rawValue)")
        }

        hotkey.onPress = { [weak coordinator] in coordinator?.handlePress() }
        hotkey.onRelease = { [weak coordinator] in coordinator?.handleRelease() }

        Task { await bootstrap() }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Flush stats synchronously so a quit mid-write can't lose data.
        stats.flush()
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
