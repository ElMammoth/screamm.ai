import AppKit
import ScreammKit

// ───────────────────────────────────────────────────────────────────────────────
// TEMPORARY — PREVIEW FLAGS.  ⚠️ REVERT THIS WHOLE BLOCK when you're done looking.
//
// Both default to FALSE and must stay that way on `main`. A `true` default here makes the
// built app show onboarding forever, never download the model, and never mark first-run
// complete — i.e. a non-working app for anyone who follows the README.
//
// To preview a screen, pass the env var instead of editing this file:
//   SCREAMM_PREVIEW=onboarding ./Screamm.app/Contents/MacOS/Screamm
//   SCREAMM_PREVIEW=settings   ./Screamm.app/Contents/MacOS/Screamm
//
// Preview mode deliberately does NOT mark onboarding complete and does NOT download.
// To remove entirely: delete this enum and its two `if Preview.…` uses below.
// ───────────────────────────────────────────────────────────────────────────────
enum Preview {
    static var onboarding: Bool { flag("onboarding", fallback: false) }
    static var settings: Bool { flag("settings", fallback: false) }

    private static func flag(_ name: String, fallback: Bool) -> Bool {
        let env = ProcessInfo.processInfo.environment["SCREAMM_PREVIEW"] ?? ""
        guard !env.isEmpty else { return fallback }
        return env.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }.contains(name)
    }
}

/// Wires ScreammKit together and owns the object graph. Menu-bar-only app (no dock icon).
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {

    private let recorder = AudioRecorder()
    private let transcriber = WhisperKitTranscriber()
    private let injector = ClipboardInjector()
    private let hotkey = HotkeyManager()

    private let overlay = OverlayController()
    private let celebration = CelebrationController()
    private let stats = StatsStore()
    private let dictionaryStore = DictionaryStore()
    private let contextStore = AppContextStore()
    private let profileStore = ProfileStore()
    private lazy var contextResolver = SystemContextResolver(store: contextStore)
    private lazy var settings = SettingsWindowController(
        dictionaryStore: dictionaryStore, contextStore: contextStore)
    private let onboarding = OnboardingWindowController()
    private var coordinator: RecordingCoordinator?
    private var menuBar: MenuBarController?
    private var onboardingActive = false
    /// TEMPORARY — set when the onboarding window was forced open by `Preview`.
    private var previewingOnboarding = false

    private static let onboardingKey = "onboardingCompleted"

    func applicationDidFinishLaunching(_ notification: Notification) {
        let menuBar = MenuBarController(stats: stats)
        self.menuBar = menuBar

        let coordinator = RecordingCoordinator(
            recorder: recorder,
            transcriber: transcriber,
            injector: injector,
            stats: stats,
            dictionary: dictionaryStore,
            context: contextResolver
        )
        self.coordinator = coordinator
        menuBar.setOpenDictionary { [weak self] in self?.settings.show() }

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
        recorder.onLevel = { [overlay] level in
            overlay.pushLevel(level)
        }

        // Success micro-reward + note the first onboarding dictation for card 4.
        coordinator.onSuccess = { [weak self, overlay] _ in
            overlay.flashSuccess()
            if self?.onboardingActive == true { self?.onboarding.model.didDictate = true }
        }
        coordinator.onMilestone = { [weak self] milestone in
            NSLog("Screamm milestone reached: \(milestone.rawValue)")
            // During onboarding, card 4 owns the celebration (no triple-fire).
            guard self?.onboardingActive != true else { return }
            guard let self else { return }
            self.celebration.celebrate(milestone, profile: self.profileStore.profile)
        }

        // Model load state → menu bar + onboarding card 4.
        transcriber.onLoadStateChange = { [weak menuBar, weak onboarding] state in
            menuBar?.reflectLoadState(state)
            onboarding?.model.loadState = state
        }

        hotkey.onPress = { [weak coordinator] in coordinator?.handlePress() }
        hotkey.onRelease = { [weak coordinator] in coordinator?.handleRelease() }
        hotkey.start()   // always on; no-ops until Accessibility is granted

        // TEMPORARY — preview hooks. Remove with the `Preview` enum above.
        if Preview.settings { settings.show() }
        if Preview.onboarding {
            previewingOnboarding = true
            startOnboarding()
            return
        }

        if UserDefaults.standard.bool(forKey: Self.onboardingKey) {
            Task { await returningBootstrap() }
        } else {
            startOnboarding()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Synchronous flushes so a quit mid-write can't lose data.
        stats.flush()
        dictionaryStore.flush()
        contextStore.flush()
        profileStore.flush()
    }

    // MARK: - First run

    private func startOnboarding() {
        onboardingActive = true
        onboarding.model.onKickoffLoad = { [weak self] in
            guard self?.previewingOnboarding != true else { return }   // TEMPORARY
            Task { await self?.transcriber.load() }
        }
        onboarding.model.onSaveName = { [weak self] name in
            self?.profileStore.update(Profile(name: Profile(name: name).displayName))
        }
        onboarding.onFinished = { [weak self] in self?.completeOnboarding() }
        onboarding.show()
    }

    private func completeOnboarding() {
        onboardingActive = false
        // TEMPORARY — a preview run must not touch your real first-run state.
        guard !previewingOnboarding else { previewingOnboarding = false; return }
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        // If the user skipped before the download started, load now.
        if case .idle = transcriber.loadState {
            Task { await transcriber.load() }
        }
    }

    // MARK: - Returning launch

    private func returningBootstrap() async {
        if Permissions.microphoneStatus != .authorized {
            _ = await Permissions.requestMicrophone()
        }
        if !Permissions.isAccessibilityTrusted {
            Permissions.promptAccessibility()
        }
        await transcriber.load()
    }
}
