import AppKit

/// Detects hold-to-talk on Right Command via NSEvent `.flagsChanged` monitors
/// (chosen over CGEventTap in eng review — no need to swallow the key, needs only
/// Accessibility). Global monitor sees other apps; local monitor sees our own window.
///
/// Right Command = keyCode 54 (left is 55). `.maskCommand` alone can't tell them apart,
/// so we key off the keyCode.
///
/// Lost-release watchdog: the global monitor is passive and can MISS the "flag off"
/// release (Spaces switch, Mission Control, modal alert) → stuck recording. While held,
/// we poll the real modifier state and force a release if the flag is gone, plus a hard
/// max-duration cap.
@MainActor
public final class HotkeyManager {

    public var onPress: (() -> Void)?
    public var onRelease: (() -> Void)?

    private let rightCommandKeyCode: UInt16 = 54
    private let maxDuration: TimeInterval

    private var globalMonitor: Any?
    private var localMonitor: Any?
    private var isDown = false
    private var pressStart: Date?
    private var watchdog: Timer?

    public init(maxDuration: TimeInterval = 60) {
        self.maxDuration = maxDuration
    }

    public func start() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: .flagsChanged) { [weak self] event in
            self?.handle(event)
            return event
        }
    }

    public func stop() {
        if let g = globalMonitor { NSEvent.removeMonitor(g) }
        if let l = localMonitor { NSEvent.removeMonitor(l) }
        globalMonitor = nil
        localMonitor = nil
        stopWatchdog()
        isDown = false
    }

    // MARK: - Private

    private func handle(_ event: NSEvent) {
        // Only react to the Right Command key itself. (Pressing left Cmd while holding
        // right fires a separate flagsChanged with keyCode 55 — ignored here.)
        guard event.keyCode == rightCommandKeyCode else { return }
        let commandDown = event.modifierFlags.contains(.command)
        if commandDown && !isDown {
            beginPress()
        } else if !commandDown && isDown {
            endPress()
        }
    }

    private func beginPress() {
        isDown = true
        pressStart = Date()
        startWatchdog()
        onPress?()
    }

    private func endPress() {
        guard isDown else { return }
        isDown = false
        stopWatchdog()
        onRelease?()
    }

    private func startWatchdog() {
        watchdog = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            // Timer fires on the main run loop; hop onto the main actor to touch state.
            MainActor.assumeIsolated {
                guard let self, self.isDown else { return }
                // Real modifier state — catches a release whose event we never received.
                if !NSEvent.modifierFlags.contains(.command) {
                    self.endPress()
                    return
                }
                if let start = self.pressStart,
                   Date().timeIntervalSince(start) > self.maxDuration {
                    self.endPress()
                }
            }
        }
    }

    private func stopWatchdog() {
        watchdog?.invalidate()
        watchdog = nil
    }
}
