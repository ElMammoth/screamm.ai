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
