# PROGRESS — Screamm.ai build log

Newest first. One line per meaningful milestone: what, and why it mattered.

## 2026-09
- **Polish pass 2** — silence gate (`AudioAnalysis.isLikelySilent`) drops silent clips before
  transcription, killing the "Thank you." hallucination. Stats card: flame+number header (side
  by side), removed encouragement line, aligned 3-metric row (words · days · saved, no washed
  chip), symmetric spacing, dropped the "…"/"≈est". Living animated flame. Docs swept current
  (CLAUDE.md repo map + status, README, TODOS, streak-and-animations.md). 46/46 tests.
- **Polish pass 1** — replaced the stats NSPopover with a custom borderless window (no arrow,
  no bg mismatch) + refined it (spring entrance, flame bounce, staggered day dots, numeric
  roll). Moved the speech pill much lower (near the Dock). Added a looping "thinking" wave
  during processing so it no longer looks frozen (reduced-motion → static). New baseline doc
  `docs/streak-and-animations.md` (streak mechanism + full animation inventory).
- **Custom dictionary** — user-editable replacements applied as the final cleanup stage
  (whole-word/phrase, case-insensitive, boundary-safe so "screenshot" survives a "screen"
  rule). `DictionaryStore` (local JSON, atomic write, corrupt-backup) + a settings window
  (menu popover "Dictionary…" / right-click "Edit dictionary…"). Fixes "screen"→"Screamm".
  40/40 tests.
- **Onboarding/stats Phase 3** — tiered milestone celebrations: confetti burst + badge in a
  separate `.nonactivatingPanel` near the pill (click-through, never steals focus),
  auto-dismiss, reduced-motion → static badge. Suppressed during onboarding. Right-click
  "Preview celebration" dogfood affordance. **Onboarding/stats feature COMPLETE for v0.2.**
- **Onboarding/stats Phase 2** — 4-card onboarding window (welcome → mic → accessibility →
  try-it), background model download with REAL progress (two-step WhisperKit.download →
  LoadState), `.regular`↔`.accessory` activation flip, first-run gate (UserDefaults),
  keyboard nav + reduced-motion. Fixed the stats popover clipping (NSHostingController
  sizingOptions).
- **Onboarding/stats Phase 1** — `StatsStore` (local JSON, Calendar-safe streaks, atomic write,
  milestones), coordinator `onSuccess`/`onMilestone` hooks, green ✓ micro-reward on the pill,
  and the stats popover (streak + week row + words/days + time saved) from the menu bar.
  28/28 tests. Planned via Mobbin + design review (6→9) + eng review + outside voice.
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
