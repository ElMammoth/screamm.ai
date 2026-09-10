# PROGRESS — Screamm.ai build log

Newest first. One line per meaningful milestone: what, and why it mattered.

## 2026-09
- **Stable self-signed cert** (`eeb1c5a`) — automated `make-cert.sh`; permissions now persist
  across rebuilds (designated requirement is stable, proven identical across two builds).
- **Brand-orange waveform overlay** (`8bcd362`) — Dynamic-Island pill, bottom-center, live
  waveform, spring pop, `#F48C02`. Added `DESIGN.md` (Duolingo-informed design system).
- **v0.1 headless dictation loop** (`cd965b8`) — Right ⌘ → record → WhisperKit turbo →
  cleanup → paste. Works live on M2 Pro, 1.83s warm decode. 13/13 tests pass.
- **Engine spike** — verified local turbo is fast enough (the go/no-go gate) before any UI.
- **Design + eng review** — office-hours design doc + plan-eng-review locked the v0.1
  architecture (state machine, watchdog, secure-input guard, warm-load). Stored in
  `~/.gstack/projects/screamm.ai/`.

## Next up
1. Duolingo-style onboarding + streak/stats + animations (planning — see `docs/`).
2. Custom dictionary (fix "Screamm"→"screen").

## Later / deferred
See `TODOS.md` and the roadmap in `DESIGN.md`.
