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

## Temporary — REVERT THIS
- **Onboarding preview flag is ON.** `Preview.onboarding = true` at the top of
  `Sources/Screamm/AppDelegate.swift` forces the first-run window on every launch. Set both
  `Preview` flags to false (or delete the enum and its two uses) once the screens are reviewed.

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
