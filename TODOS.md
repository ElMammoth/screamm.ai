# Screamm.ai — TODOS

## Reported broken (dogfooding, 2026-09-11) — fix next

- **Spoken lists don't fire in the real app, English OR French.** `SpokenListFormatter` passes its
  unit tests, so the bug is between real Whisper output and the formatter — not in the formatter's
  logic. Prime suspects, in order: (1) **auto-detect only knows English ordinals** (`first…tenth`),
  so French ("premièrement, deuxièmement") can never match — a known gap, not a bug; (2) real
  speech probably uses **counting** ("one, two, three" / "un, deux, trois"), which the design doc
  specified and the implementation never covered; (3) the transcript may not look like the test
  fixtures at all. **Do this first: log the raw transcript and the post-cleanup text for a real
  dictation** and compare — do not guess. Then add counting + French/multilingual ordinals.
- **Per-app code mode doesn't trigger for the VS Code integrated terminal.** Dictating there still
  capitalizes and punctuates. The frontmost app is captured at key-press in `RecordingCoordinator`
  and resolved by `SystemContextResolver` (NSWorkspace bundle id). Verify what bundle id is
  actually seen when VS Code is focused (`com.microsoft.VSCode` vs Cursor/Insiders/Codium builds)
  and whether the press-time capture is racing the overlay/panel taking focus. Log the resolved
  id + mode per dictation.
- ~~The settings window is not user-friendly.~~ **FIXED** — rebuilt with a sidebar, explained
  rows, real app icons, and an About pane carrying the privacy promise.
- **Name personalization was pulled back** (2026-09-11): "Cyprien's day streak" reads oddly on
  your own machine — you already know whose streak it is. The name is now asked at onboarding
  only and used just in the celebration line. Revisit only if there's a use that earns it.

## From the YC-style review (2026-09-11) — ranked

Every item below was verified against the source, not taken on faith.

### P0 — breaks the core promise
- **Startup is not offline.** `WhisperKitTranscriber.load()` calls `WhisperKit.download(...)`
  unconditionally on EVERY launch (`Transcription/WhisperKitTranscriber.swift:37`), and that
  function hits HuggingFace to resolve filenames before checking for a local snapshot. No
  network → `.failed` → dead menu-bar icon. **Fix:** look for the existing model folder first
  and build `WhisperKitConfig(modelFolder:download:false)` directly; only call `download` when
  the folder is absent. This is the single biggest gap between what the README promises and
  what the app does.

### P1 — silent data loss in the paste path (`Injection/ClipboardInjector.swift`)
Four failure modes, all silent, none tested:
- Clipboard restores after a fixed **0.15s** (line 43). Electron apps (Slack, VS Code, Notion)
  routinely take longer to service a synthetic ⌘V → the user gets their OLD clipboard pasted.
  Wait on `NSPasteboard.changeCount` or lengthen it substantially.
- Restore only handles `.string` (line 46) — dictating after copying an image or file
  **destroys that clipboard**.
- `postCommandV()` never checks `AXIsProcessTrusted()`. Without Accessibility, `CGEvent.post`
  silently no-ops and the transcript is wiped 0.15s later. Text simply vanishes.
- The secure-input fallback sets a **tooltip** (`MenuBarController.flashSecureInputNotice`),
  which is invisible unless you're already hovering the menu bar — which you aren't, because
  you're typing somewhere else.
- **Fix:** extract `PasteboardWriting` + `SecureInputProbing` seams (the same protocol-seam
  pattern used everywhere else in ScreammKit) and test all four.

### P1 — failures are invisible
- `AppDelegate.onError` is `NSLog` and nothing else (`AppDelegate.swift`). Mic unavailable,
  decode throw, `notLoaded` — all produce a successful-looking dictation that yields no text.
- Three of `RecordingCoordinator`'s exits (`min-duration`, `silence gate`, `empty cleanup`)
  do `state = .idle; return` with **no signal at all**.
- **A press during `.transcribing` is silently dropped** (`canStartRecording` is `.idle`-only).
  Decode is ~1.8s warm, far longer for a long utterance, so in burst use this is the thing
  that will feel broken first. Queue it or show a "still thinking" state.
- **Fix:** give the pill a visible error//busy state. The user is already looking at the pill.

### P2 — the green ✓ probably never renders
`runTranscription` sets `.injecting`, injects, fires `onSuccess`, and sets `.idle` **all in one
synchronous main-actor tick**, so the 0.15s success animation races the 0.22s hide that starts
at the same instant. The README sells this flash as the core feel. Hold `.injecting` briefly.

### P2 — concurrency
- `WhisperKitTranscriber` is a plain `final class` with mutable `pipe`/`loadState`, no actor and
  no `Sendable`; `setState` hops to main, so `loadState` is **stale right after `await load()`
  returns** — which is exactly what `completeOnboarding` branches on.
- `AudioRecorder.append` runs on the realtime render thread and does buffer allocation, array
  allocation, `NSLock.lock()` and a `DispatchQueue.main.async`, ~47×/sec. All four are on the
  "never do this on the audio thread" list; the lock is a priority-inversion hazard.
- `isRunning` is unsynchronized while `samples` is lock-protected — inconsistent discipline in
  one object.
- **Fix:** turn on `swiftLanguageMode(.v6)` + `StrictConcurrency` and let the compiler find the
  rest. Cheapest quality win available.

### P2 — test suite measures the wrong things
74 tests, but **~74% cover pure string manipulation and the streak counter**, and 9 of them
guard `Profile` copy that is no longer rendered anywhere. **Zero** tests for `ClipboardInjector`
(66 lines), `HotkeyManager` (102), `AudioRecorder` (125), `WhisperKitTranscriber` (81),
`Permissions` (50), or any of `Sources/Screamm/`. Untested coordinator paths: transcriber
throwing, recorder throwing, press-during-transcribing, `pendingMode` capture (the per-app
feature that's actually broken), and the dictionary path through the coordinator.
Also: `waitUntilIdle` in the tests is a polling sleep that **falls through instead of failing**,
so a hung coordinator makes the two absence-asserting tests pass for the wrong reason.

### P3 — repo hygiene
- No `.github/` at all: no CI. A green `swift test` check is the minimum signal for a repo
  asking for PRs.
- `ScreammSpike` is still a shipped target; CLAUDE.md has said "delete eventually" since v0.1.
- `CLAUDE.md` at the root of a public repo contains machine-local paths and internal notes.

### Positioning (the part that isn't code)
- The wedge is **compliance, not privacy-as-a-value**. People under an NDA/DPA are *forbidden*
  from cloud dictation and currently type. That's an unlock, not a preference switch. Lead with it.
- 8 of the 9 README feature rows are table stakes vs Superwhisper. The differentiated one
  (per-app code mode) is buried and currently broken.
- macOS 26's improved built-in dictation is the real competitor. The answer has to be output
  quality, and **nothing in the repo measures output quality** (no WER, no accuracy harness).
- Explicitly do NOT build next: the mascot (already cost two commits), more streak surface,
  MLX cleanup, or streaming transcription.

### Recommended order
Offline startup → clipboard seams + tests → visible errors → notarized DMG → 10 real users.

## Temporary — preview flags
- `Preview` in `Sources/Screamm/AppDelegate.swift` defaults to **false** and must stay that way
  on `main` (a `true` default ships an app that shows onboarding forever and never downloads
  the model). Preview a screen with the env var instead:
  `SCREAMM_PREVIEW=onboarding ./Screamm.app/Contents/MacOS/Screamm`

## Cleanup before a public release (v1)
- **Notarization + distribution** — paid Apple Developer ID, notarized DMG, Homebrew cask,
  Sparkle auto-update. Currently self-signed/personal only (`Scripts/`).
- A simple landing page (the README already reads as one; a real site is the next step).

## Accuracy / engine
- **Better voice-activity detection** — the current silence gate (`AudioAnalysis.isLikelySilent`,
  peak+RMS thresholds) catches true silence but not speech-shaped background noise. Consider
  WhisperKit's `EnergyVAD` or a proper VAD so noisy rooms don't hallucinate either.
- **Streaming transcription** — show words as you speak; lower felt latency.
- **Optional local-LLM cleanup** (MLX) — grammar/formatting/tone as an opt-in stage.

## Features
- **Per-app context — next stages.** v1 (code mode: auto-skip capitalization in dev apps) is
  DONE (`ScreammKit/Context/`). Remaining: per-app **custom dictionary** (e.g. Xcode:
  "screen"→"UIScreen") and per-app **forced language** (French Slack → French, via WhisperKit
  decodeOptions). Would extend `AppContextSettings` into a full per-app profile + editor.
- **Settings depth** — model tier switch (turbo/large-v3), hotkey rebind UI, translate-to-English
  toggle, streak-freeze ("pause & preserve").

## Deferred (post-v0.1)

### Idle model unload (memory vs latency)
- **What:** After N minutes idle, unload the resident Whisper model to free memory; reload on next dictation.
- **Why:** The warm large-v3-turbo model holds ~1.5GB in unified memory continuously. On an 8GB Mac that's meaningful pressure.
- **Pros:** Frees ~1.5GB when not dictating; friendlier on low-RAM Macs.
- **Cons:** First dictation after idle pays cold-load + ANE re-JIT latency (the exact thing v0.1 designs away by keeping warm).
- **Context:** v0.1 keeps the model always warm (correct default for a fast dictation tool). This TODO adds a *configurable* idle-unload timer, default OFF on 16GB+, optionally ON for low-RAM Macs. Surfaced in the eng-review performance pass.
- **Depends on:** Transcriber warm-load implementation (v0.1) + a Settings surface (v0.2).
