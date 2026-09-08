import AppKit
import Carbon
import CoreGraphics

/// Pastes text into the focused app via clipboard + synthetic ⌘V, then restores the
/// previous clipboard.
///
///   save clipboard ─▶ set text ─▶ post ⌘V ─▶ (delay) ─▶ restore clipboard
///
/// Hardening from eng review:
///  - Secure input is SYSTEM-WIDE (not per-field). If any app holds it, we do NOT paste;
///    we leave the transcript on the clipboard and notify "press ⌘V". Never blast into a
///    password field, never lose the text.
///  - Restore is delayed because paste is async in the target and there's no completion
///    signal. The delay is tunable, not a guarantee.
public final class ClipboardInjector: TextInjecting {

    private let restoreDelay: TimeInterval

    /// Called (with the text, already on the clipboard) when secure input blocked the paste.
    public var onSecureInputBlocked: ((String) -> Void)?

    public init(restoreDelay: TimeInterval = 0.15) {
        self.restoreDelay = restoreDelay
    }

    public func inject(_ text: String) {
        guard !text.isEmpty else { return }
        let pasteboard = NSPasteboard.general
        let previous = pasteboard.string(forType: .string)

        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // System-wide secure input active → don't paste; leave on clipboard + notify.
        if IsSecureEventInputEnabled() {
            onSecureInputBlocked?(text)
            return
        }

        postCommandV()

        DispatchQueue.main.asyncAfter(deadline: .now() + restoreDelay) {
            pasteboard.clearContents()
            if let previous {
                pasteboard.setString(previous, forType: .string)
            }
        }
    }

    /// Posts ⌘V as synthetic key events. `virtualKey: 9` is 'v' (kVK_ANSI_V).
    private func postCommandV() {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 9

        guard
            let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
            let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false)
        else { return }

        down.flags = .maskCommand
        up.flags = .maskCommand
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
