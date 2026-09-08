# Screamm.ai

Open-source, **100% on-device** voice-to-text for macOS. Hold a key, talk, release,
and polished text lands wherever your cursor is. Your voice never leaves your Mac.

An open-source alternative to Wispr Flow, powered by [WhisperKit](https://github.com/argmaxinc/WhisperKit)
(Whisper `large-v3-turbo` on the Apple Neural Engine). No cloud, no API keys, no accounts,
no telemetry.

> **Status: v0.1, in progress.** The headless end-to-end loop (hold Right ⌘ → record →
> transcribe → clean up → paste) is built and tested. Polish (floating pill overlay,
> settings, onboarding, custom dictionary, per-app context) is v0.2. See `TODOS.md`.

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
