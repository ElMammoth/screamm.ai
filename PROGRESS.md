# PROGRESS — Screamm.ai build log

Newest first. One line per meaningful milestone: what, and why it mattered.

## 2026-09
- **v0.4 — Screammy.** The orange squid from the reference art now sits on the waveform pill and
  hooks his tentacles around both ends while you dictate. Native SwiftUI, no art assets: one
  `Canvas`, ~14 shapes, six tentacles on independent sine phases, blink, gaze, eyebrows, teal
  handlebar moustache. Moods follow the recording state (listening / thinking / success). Two
  non-obvious constraints drove the design — a deep contour, because an orange squid on an orange
  pill is otherwise invisible, and limbs that stop at the pill's top rim, because anything lower
  covers the waveform and the success ✓. Perf was a gate, not a nicety (he animates while Whisper
  decodes): **0.065 ms/frame, 0.19% of one core at 30fps**. Pulled name personalization back out
  of the stats card at the same time. 74/74 tests.
- **v0.3 — spoken lists + your name.** Two shipped features. (1) `SpokenListFormatter`: say a
  list, get a list. "First, buy milk. Second, call mom." → a real numbered list; explicit
  "bullet list"/"new bullet"/"end list" commands too. Deliberately conservative — needs
  consecutive ordinals from "first" with real content in each, so "I was first and she was
  second" stays prose. (2) `ProfileStore` + a name card in onboarding (question-as-headline,
  one field, skippable) + a "You" settings tab. Every personalized string is nil-safe
  (`possessive`, `addressed`): "Alex's day streak" / "Your day streak", "Nice work, Alex" /
  "Nice work!". Also removed the "Preview celebration" dev affordance and folded the
  right-click menu into a single "Settings" item. 74/74 tests.
- **Per-app context (code mode)** — the signature differentiator, v1: dictating into a dev app
  (Xcode/VS Code/Terminal/Cursor/Zed/…) auto-skips sentence capitalization so code stays as
  spoken (`func`, not `Func`). Frontmost app captured at press; `CleanupMode` in the pipeline;
  `AppContextStore` + a "Per-app" settings tab (toggle + Add app…). 50/50 tests.
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
Three bugs found while dogfooding, detailed at the top of `TODOS.md`:
1. Spoken lists don't fire on real speech (English or French) — instrument the real transcript
   before guessing; then add counting + non-English ordinals.
2. Per-app code mode misses the VS Code integrated terminal.
3. The settings window needs a real UX pass.

## Later / deferred
See `TODOS.md` and the roadmap in `DESIGN.md`.
