# Streak Mechanism & Animation Baseline

The definitive reference for how Screamm's streak/stats work and every animation currently in
the app. This is the **baseline** captured before we add new motion. Keep it current.

Source of truth in code:
- Streak logic: `Sources/ScreammKit/Stats/Stats.swift` (`StatsData`) + `StatsStore.swift`
- Design tokens: `DESIGN.md` / `Sources/Screamm/Overlay/Theme.swift`

---

## Part 1 — The streak mechanism

### 1.1 What a "streak" is

`currentStreak` = the number of **consecutive local calendar days** on which you completed at
least one successful dictation. A day "counts" the moment one dictation is recorded
(`RecordingCoordinator` → `StatsStore.recordDictation` → `StatsData.record`). There is no
minimum word count; a single successful dictation marks the day.

A "successful dictation" is one that passed every `RecordingCoordinator` gate: **min-duration**,
the **silence gate** (`AudioAnalysis.isLikelySilent` — drops clips with no speech energy, so a
silent hold never counts, pastes, or hallucinates "Thank you."), and **non-empty** cleaned
output. Silent/empty attempts never touch stats.

`longestStreak` = the best `currentStreak` ever reached.

### 1.2 Data model (`StatsData`, persisted to `~/Library/Application Support/Screamm/stats.json`)

| Field | Meaning |
|---|---|
| `schemaVersion` | Migration guard (currently 1) |
| `totalWords` | Lifetime words dictated |
| `totalDictations` | Lifetime successful dictations |
| `perDay` | `["yyyy-MM-dd": wordCount]`, local day keys (for the week row) |
| `currentStreak` | Consecutive-day count |
| `longestStreak` | Best-ever streak |
| `lastActiveDay` | Start-of-day of the last active day |
| `milestonesReached` | Set of milestone ids already fired (so each fires once) |

### 1.3 The stages / transitions

`record(wordCount:at:calendar:)` runs this decision, using **`Calendar` day comparison**
(never 86400-second math, so DST days of 23/25h are correct):

```
                       ┌─────────────── first ever (lastActiveDay == nil)
                       │                 → currentStreak = 1
   record(at) ─────────┤
                       │  today == lastActiveDay      → streak UNCHANGED (same day)
                       │  today == lastActiveDay + 1  → streak + 1        (consecutive)
                       │  today  > lastActiveDay + 1  → streak = 1        (gap resets)
                       └  today  < lastActiveDay      → clock moved BACK:
                                                        count words, DO NOT touch streak
```

- **Day boundary:** `calendar.startOfDay(for:)`. A dictation at 11:59pm then 12:01am counts as
  **two consecutive days** (correct, not a bug).
- **"The day before"** is `calendar.date(byAdding: .day, value: -1, to: today)` compared with
  `isDate(inSameDayAs:)` — timezone/DST safe.
- **Clock-backwards guard:** if `today < lastActiveDay` (user changed the clock / traveled),
  words are still counted but the streak and `lastActiveDay` are left untouched, so a streak
  can never freeze or jump to a future date.
- After a normal record, `longestStreak = max(longestStreak, currentStreak)` and
  `lastActiveDay = today`.
- `perDay[todayKey] += wordCount`.

### 1.4 Milestones

Checked after each record, **highest priority first**, each firing exactly once (tracked in
`milestonesReached`):

| Milestone | Condition |
|---|---|
| `streak30` | currentStreak ≥ 30 |
| `streak7` | currentStreak ≥ 7 |
| `words10k` | totalWords ≥ 10,000 |
| `words1k` | totalWords ≥ 1,000 |
| `firstDictation` | totalDictations ≥ 1 |

`record` returns the single highest-priority **newly** reached milestone (while marking all
newly reached), which `RecordingCoordinator.onMilestone` forwards to the celebration (see 2.3).
During onboarding, card 4 owns the moment and milestone celebrations are suppressed.

### 1.5 Time saved (estimate)

`timeSavedMinutes = totalWords × (1/40 − 1/150)` — typing ~40 wpm vs speaking ~150 wpm. Always
shown labeled `~est`. Displayed as hours (≥60 min) or minutes.

### 1.6 Persistence & safety

- Written **atomically** (`Data.write(.atomic)` = temp + rename) on a **serial background
  queue**, from a value-type snapshot taken on the main thread (no main-thread stall, no race).
- `flush()` is called synchronously in `applicationWillTerminate` so a quit mid-write can't lose data.
- **Corrupt file** → backed up to `stats.json.bak`, start empty. **Missing file** → empty.

### 1.7 Week row (stats card)

The header shows the last 7 days (S–S letters via `calendar.veryShortWeekdaySymbols`). A day is
filled with a white circle + orange ✓ when `perDay` has an entry for it; today gets a brighter
ring. Meaning is never color-only (the ✓ glyph carries it).

---

## Part 2 — Animation inventory (baseline)

All motion is **spring-first, ≤0.4s** (except confetti) and **respects reduced motion** via
SwiftUI `@Environment(\.accessibilityReduceMotion)`, degrading to a cross-fade or a static state.

### 2.1 Waveform pill (`Overlay/WaveformView.swift`, `OverlayController.swift`)

The bottom-center dictation pill. States and their motion:

| State | Motion | Spec |
|---|---|---|
| Slide-in | the whole panel slides UP from ~46px below + fades in | `NSAnimationContext` easeOut 0.32s (`OverlayController.show`); reduced-motion → plain fade |
| Slide-out | slides down ~30px + fades, then panel removed | easeIn 0.22s (`OverlayController.hide`) |
| Recording (live) | bars follow live RMS mic levels | `easeOut 0.09` on `levels`; brand-orange fill |
| **Thinking / processing** | **looping sine wave across the bars** (never freezes) | `TimelineView(.animation)`, `sin(t·3.2 + i·0.34)`; deepens to `brandDeep` |
| Success | green ✓ replaces bars, brief flash before pop-out | `easeInOut 0.15` on `success`; green `#33C759`-ish |
| Position | bottom-center, `visibleFrame.minY + 24` (low, near the Dock) | `OverlayController.reposition` |
| Glow | soft brand-orange shadow, radius 16 | in `WaveformView.background` |

Panel: borderless `.nonactivatingPanel`, click-through, all Spaces.

### 2.2 Stats card (`StatsPanel.swift`, `StatsWindowController.swift`)

Hosted in a **borderless transparent window (no system arrow)**; the card draws its own
18pt rounded corners, and the window shadow follows that shape.

| Element | Motion | Spec |
|---|---|---|
| Card entrance | scale 0.97→1 (anchor top) + fade | `spring(response: 0.34, damping: 0.82)`, `appear` |
| Flame | **living flicker** (licks up from base, sway, pulsing heat-glow) + bounce-in on appear | `AnimatedFlame` — `TimelineView` with mixed sine frequencies; reduced-motion → static flame |
| Header layout | flame + streak number side by side, "DAY STREAK" caption below | (no encouragement line) |
| Metrics | aligned 3-col row `WORDS · DAYS · SAVED`, thin dividers, no tinted background | — |
| Streak number | numeric roll on change | `.contentTransition(.numericText())` |
| Week dots | **staggered** spring-in, left→right | `spring(0.4, 0.7).delay(0.06 + i·0.04)` |
| Dismiss | outside-click (global monitor) or status-item re-click | no animation (order-out) |

Reduced motion: everything appears immediately, no scale/stagger.

### 2.3 Milestone celebration (`Overlay/CelebrationView.swift`, `CelebrationController.swift`)

Separate `.nonactivatingPanel` (never steals typing focus), bottom-center at
`visibleFrame.minY + 80` (just above the pill), auto-dismiss ~2s.

| Element | Motion | Spec |
|---|---|---|
| Confetti | 70 particles, burst up/out + gravity, fade over 1.7s | `Canvas` + `TimelineView(.animation)`, `y = vy·t + 320·t²` |
| Badge | spring scale 0.6→1 + fade | `spring(response: 0.4, damping: 0.6)` |
| Reduced motion | **no confetti**, static badge only | — |

Tiered: the per-success green ✓ (2.1) fires every time; confetti only on the big milestones (2.4).

### 2.4 Onboarding (`Onboarding/OnboardingView.swift`)

| Element | Motion | Spec |
|---|---|---|
| Card transitions | spring between the 4 cards | `spring(response: 0.35, damping: 0.82)` on `model.card` |
| Progress bar | width grows per card | animated via the card spring |
| Permission ✓ | circle swaps to a green check | state-driven |
| Warming-up | real download `ProgressView(value:)` or indeterminate spinner | from `LoadState.downloading` |
| Reduced motion | card transitions disabled | `@Environment(\.accessibilityReduceMotion)` |

### 2.5 Menu bar (`MenuBarController.swift`)

No continuous animation. The status item swaps SF Symbols by state (idle → `flame.fill` +
streak number / `mic.fill`; recording → `mic.fill`; transcribing → `waveform`; injecting →
`checkmark`), template-tinted, monospaced-digit number (no width jitter).

### 2.6 Settings / dictionary window

No notable animation (standard titled window, text fields).

---

## Reduced-motion policy (single source)

Every animated surface reads SwiftUI `@Environment(\.accessibilityReduceMotion)` and degrades:
pill/celebration/onboarding/stats-card all skip springs/confetti and show the end state or a
short cross-fade. This is a **hard requirement** — never ship motion that ignores it.
