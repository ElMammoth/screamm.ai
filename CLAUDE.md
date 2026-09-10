# CLAUDE.md — AI context for Screamm.ai

Read this first. It tells any AI assistant what Screamm is, where everything lives, how to
build/run it, and the non-obvious gotchas. Keep it up to date when things change.

## What Screamm is

Open-source, **100% on-device** macOS menu-bar dictation app. Hold Right ⌘, talk, release,
and cleaned text pastes wherever the cursor is. Powered by WhisperKit (Whisper
`large-v3-turbo` on the Apple Neural Engine). No cloud, no API keys, no accounts, no
telemetry. Open-source alternative to Wispr Flow. Author: ElMammoth (personal-first, public
later). Repo: https://github.com/ElMammoth/screamm.ai

## Current status (keep this current)

- **v0.1 headless loop: SHIPPED + working live.** Right ⌘ → record → WhisperKit turbo →
  rule cleanup → clipboard+⌘V paste. Verified on M2 Pro: 1.83s warm decode.
- **Waveform overlay: DONE.** Brand-orange Dynamic-Island pill, bottom-center, live
  waveform, spring pop, deepens while transcribing.
- **Stable signing cert: DONE.** Permissions now persist across rebuilds.
- **Onboarding/stats Phase 1: DONE.** `StatsStore` + streak/stats popover + success micro-reward.
  Plan: `docs/onboarding-stats-plan.md`. Phase 2 (onboarding window) + Phase 3 (celebrations) next.
- **NEXT (in order):** 1) onboarding/stats Phase 2 (onboarding window) + Phase 3 (milestone
  celebrations), 2) custom dictionary (fixes "Screamm"→"screen").
- Deferred items: `TODOS.md`. Roadmap detail: the design doc (see "Where docs live").

## Repo map

```
Sources/
  ScreammKit/            # testable logic + macOS integrations (the library)
    Core/                # Protocols.swift (seams), RecordingCoordinator.swift (state machine)
    State/               # RecordingState.swift (idle→recording→transcribing→injecting)
    Audio/               # AudioRecorder.swift (AVAudioEngine tap → 16kHz mono + RMS levels)
    Transcription/       # WhisperKitTranscriber.swift (resident + warm-up inference)
    Cleanup/             # CleanupPipeline.swift (fillers, spoken commands, capitalization)
    Injection/           # ClipboardInjector.swift (paste+restore, secure-input guard)
    Hotkey/              # HotkeyManager.swift (NSEvent .flagsChanged + lost-release watchdog)
    Permissions/         # Permissions.swift (AX + mic, deep-links)
  Screamm/               # the thin menu-bar app (executable)
    Main.swift           # @main @MainActor entry
    AppDelegate.swift    # wires ScreammKit together, owns the object graph
    MenuBarController.swift
    Overlay/             # Theme.swift (brand), WaveformView.swift, OverlayController.swift
  ScreammSpike/          # throwaway engine spike (latency gate) — delete eventually
Tests/ScreammKitTests/   # Swift Testing suite (Cleanup + Coordinator)
Scripts/                 # make-cert.sh (self-signed cert), build-app.sh (build+sign .app)
Resources/               # Info.plist (LSUIElement, mic usage), Screamm.entitlements (no sandbox)
docs/                    # feature plans (in-repo, versioned) — see below
README.md DESIGN.md TODOS.md SPIKE.md PROGRESS.md
```

## Build / run / test

```bash
swift build                                   # compile everything
swift test                                    # run the suite
./Scripts/make-cert.sh                         # create stable self-signed cert (once)
SCREAMM_CERT="Screamm Self-Signed" ./Scripts/build-app.sh   # build + sign Screamm.app
pkill -x Screamm 2>/dev/null; open Screamm.app # relaunch
./Screamm.app/Contents/MacOS/Screamm           # run in terminal to see logs
```

## Non-obvious gotchas (these will waste your time)

- **Build system:** with full Xcode installed, `swift build` works. With ONLY Command Line
  Tools (Swift 6.4), the default XCBuild backend errors ("Unknown error parsing property
  list") — use `swift build --build-system native`.
- **Signing / TCC:** ad-hoc signing (`codesign -s -`) does NOT persist Accessibility/Mic
  across rebuilds (cdhash changes). The stable self-signed cert "Screamm Self-Signed" gives
  a constant designated requirement (`identifier "ai.screamm.Screamm" and certificate leaf =
  H"..."`), so permissions stick. `build-app.sh` uses the stable cert if present, else ad-hoc.
- **Switching identity re-prompts once:** going ad-hoc→stable (or changing the cert) changes
  the identity, so macOS requires ONE fresh Accessibility/Mic grant. Remove the stale
  "Screamm" entry in System Settings → Privacy → Accessibility, relaunch, re-grant. Then it sticks.
- **OpenSSL 3 PKCS12:** Homebrew openssl 3 writes p12s Apple's `security` can't import unless
  you pass `-legacy` (LibreSSL doesn't need it). `make-cert.sh` handles both.
- **Hotkey:** Right ⌘ is keyCode 54 (left is 55); `.maskCommand` can't tell them apart. The
  NSEvent global monitor can MISS the key-release (Spaces/Mission-Control switch) → the
  watchdog (modifier-flags poll + max-duration) recovers it.
- **Secure input:** `IsSecureEventInputEnabled()` is SYSTEM-WIDE, not per-field. Treat it as
  a hint; when true, don't silently paste — leave text on clipboard + notify.
- **Whisper hallucinates on silence** ("Thank you."); the min-duration gate + empty-suppression
  in RecordingCoordinator handle it.
- **Repo hygiene:** `$HOME` is itself a git repo on this machine. This project has its own
  `.git` — always run git commands from the project dir.

## Conventions

- Swift Testing (`import Testing`, `@Test`) for units. UI/live paths are dogfooded manually.
- Protocol seams for anything with a live dependency (Transcribing, TextInjecting,
  AudioRecording) so logic is testable with fakes.
- `@MainActor` for UI + coordinator; audio tap runs off-main and hands back via callbacks.
- Privacy is the brand: on-device only, no telemetry, local-only any stats.

## Where docs live

- `DESIGN.md` — design system (brand `#F48C02`, Duolingo-informed onboarding/retention). Source of truth for UI.
- `README.md` — public-facing build/run/how-it-works.
- `TODOS.md` — deferred work.
- `docs/` — per-feature plans (in-repo, versioned). Start here for what's being built next.
- `PROGRESS.md` — running build log (what shipped, when, why).
- Machine-local (NOT in repo): `~/.gstack/projects/screamm.ai/` holds the original office-hours
  design doc + eng-review test plan. Useful history, but not guaranteed present on another machine.

## Skill routing (gstack)

- New feature / brainstorm → `/office-hours`; architecture review → `/plan-eng-review`;
  design plan review → `/plan-design-review`; ship/PR → `/ship`; bugs → `/investigate`.
