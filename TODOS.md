# Screamm.ai — TODOS

## Cleanup before a public release (v1)
- **Remove the "Preview celebration" dev affordance** — right-click menu item wired in
  `MenuBarController` + `AppDelegate` (`setPreviewCelebration`). Purely for dogfooding.
- **Notarization + distribution** — paid Apple Developer ID, notarized DMG, Homebrew cask,
  Sparkle auto-update. Currently self-signed/personal only (`Scripts/`).
- Public-facing README polish + a simple landing page.

## Accuracy / engine
- **Better voice-activity detection** — the current silence gate (`AudioAnalysis.isLikelySilent`,
  peak+RMS thresholds) catches true silence but not speech-shaped background noise. Consider
  WhisperKit's `EnergyVAD` or a proper VAD so noisy rooms don't hallucinate either.
- **Streaming transcription** (v0.3) — show words as you speak; lower felt latency.
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
