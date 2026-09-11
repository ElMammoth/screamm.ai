# Screamm.ai

Open-source, **100% on-device** voice-to-text for macOS. Hold a key, talk, release,
and polished text lands wherever your cursor is. Your voice never leaves your Mac.

An open-source alternative to Wispr Flow, powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit)
(Whisper `large-v3-turbo` on the Apple Neural Engine). No cloud, no API keys, no accounts,
no telemetry.

> **Status: working v0.3** (personal-first; a notarized public release is a later milestone).

## Features

- **Hold to talk, on-device.** Hold Right ⌘, speak, release — cleaned text pastes where your cursor is.
- **Say a list, get a list.** "First, buy milk. Second, call mom. Third, ship it." pastes as a real
  numbered list. Or say "bullet list" / "new bullet" / "end list" explicitly. Conservative on
  purpose — "first, I went to the store" stays prose.
- **Bottom-center waveform pill** that slides up, shows live audio, and a "thinking" wave while it works.
- **Streak + stats** (words dictated, days used, estimated time saved) with milestone celebrations —
  all **local-only**, no accounts, no telemetry.
- **Knows your first name** (optional, skippable) so the streak and celebrations feel like yours.
  Stored on your Mac, nowhere else.
- **Friendly first-run onboarding** with in-context permission priming.
- **Custom dictionary** to fix mistranscriptions (e.g. "screen" → "Screamm").
- **Per-app code mode** — dictating into Xcode/VS Code/Terminal keeps code lowercase (no auto-capitalization).
- **Silence + hallucination gates** so it never types "Thank you." when you said nothing.
- Rule-based cleanup (fillers, "new line", capitalization). Auto-detect language.

See `docs/streak-and-animations.md` for the streak logic + animation baseline, and `TODOS.md` for what's next.

## Requirements

- Apple Silicon Mac (M1 or newer)
- macOS 14+
- Full Xcode (for building the app; the CLI spike only needs Command Line Tools)

## Try the engine spike (fastest)

Answers "is local turbo fast enough on my Mac?" without building the whole app.

```bash
swift run --build-system native ScreammSpike sample.aiff
```

See `SPIKE.md`. On an M2 Pro this measured **1.83s warm decode** (the viability gate is ≤2s).

## Build the app

macOS ties permissions to an app's code signature, so create a **stable self-signed
certificate** once (no Apple Developer ID, $0). Ad-hoc signing does NOT persist
permissions across rebuilds.

```bash
./Scripts/make-cert.sh          # prints the 2-minute Keychain Access steps
SCREAMM_CERT="Screamm Self-Signed" ./Scripts/build-app.sh
open ./Screamm.app
```

First launch: grant **Microphone** + **Accessibility** when prompted, then it downloads
the turbo model once (~600MB–1.5GB). Look for 🎙️ in the menu bar. **Hold Right ⌘** to
dictate; release to paste into whatever app is focused.

## How it works

```
Right ⌘ (hold) ──▶ AudioRecorder ──▶ WhisperKitTranscriber ──▶ CleanupPipeline ──▶ ClipboardInjector
   HotkeyManager      AVAudioEngine       large-v3-turbo          rule-based           clipboard + ⌘V
   (NSEvent monitor    → 16kHz mono        (resident + warm)       fillers, commands,   + restore, with
    + lost-release      Float buffer                                capitalization       secure-input guard
    watchdog)                                                                             )
                              all orchestrated by RecordingCoordinator (RecordingState machine)
```

Everything runs on-device. Audio is discarded the instant it's transcribed; no history,
no logging, no network except the one-time model download.

- `Sources/ScreammKit/` — the logic + macOS integrations (testable; `swift test`)
- `Sources/Screamm/` — the thin menu-bar app
- `Sources/ScreammSpike/` — the throwaway engine spike

## Development

```bash
swift build        # build everything
swift test         # run the suite (ScreammKit)
```

## License

MIT
