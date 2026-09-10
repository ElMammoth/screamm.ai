# Plan: Duolingo-style onboarding + streak/stats + celebrations

Status: DRAFT (planning — do not build yet)
Feature target: v0.2
Design source of truth: `DESIGN.md` (brand `#F48C02`, Duolingo-informed)

## Goal

Bring Duolingo's warmth and retention psychology to Screamm: a value-first onboarding that
gets you dictating in under 60 seconds, a streak + stats surface that rewards daily use, and
tasteful celebration moments. All **local-only, no accounts, no telemetry** — privacy is the brand.

## The key adaptation (do not miss this)

Duolingo's onboarding is 20 fullscreen steps with account creation. **Screamm is a menu-bar
utility.** We take the FEEL — progress, personality, chunky cards, commitment, permission
priming, celebration — and compress it hard into small windows/popovers. No 20-screen flow,
no account, no fullscreen takeover.

## Real references (Mobbin)

- Onboarding: [Duolingo](https://mobbin.com/flows/b0b4f93f-5637-46ec-9d77-49ecda6b991d) —
  persistent progress bar, mascot + speech bubble per step, chunky option cards, "I'M
  COMMITTED" commitment moment, permission priming ("I'll cheer you on...") before the system
  dialog, deferred/"LATER" signup.
- Streak: [Speak](https://mobbin.com/screens/7acbb2fc-3817-408f-9db3-25380bb43706),
  [Yazio](https://mobbin.com/screens/84b1eadf-f94e-43a7-84e6-838d039aeaa1),
  [Me+](https://mobbin.com/screens/55df22a2-c3c6-4961-9e2e-b5eba22518a2) — big flame + number,
  encouraging line, week row of checkmarks, milestone progress, kind loss-aversion ("Pause & preserve").
- Stats: [Brick](https://mobbin.com/screens/931c1533-a2f7-4b18-9aad-0b737b9eb428) (huge metric +
  relatable comparison), [Letterboxd](https://mobbin.com/screens/af7b4f2a-9a01-4950-bbb9-bc5857593598)
  (big-number grid), [Oura](https://mobbin.com/screens/426872c9-54b7-4922-a008-7fad40e1d6ef)
  (congratulatory framing).
- Celebration: [Runna](https://mobbin.com/screens/0e8a24e7-31ae-4657-bc16-6ace3abc70ea)
  (confetti + badge), [Nibble](https://mobbin.com/screens/5385f415-3d0a-4d60-86f2-b50d6aaa7763)
  (confetti + score), [How We Feel](https://mobbin.com/screens/060d6644-87d1-4497-833d-8bbf011eee25).

## 1) Onboarding — a small friendly window, 4 cards, <60s

Shown on first launch (no `onboardingCompleted` flag). One window (~480×560), brand-orange
accents, chunky rounded cards, a top progress bar, spring transitions between cards.

1. **Welcome** — the orange waveform animating as the "character" (no mascot for v0.2 —
   design-review decision). "Talk. It types. Everywhere on your Mac." One privacy line:
   "100% on-device. Your voice never leaves this Mac." CTA: **Get started**.
   **On this card, kick off the model download in the background** (design-review decision) so
   it's usually ready by card 4; card 4 gates on "ready" with a "Warming up ~30s" state if not.
2. **Microphone (priming, then system dialog)** — "Screamm needs your mic to hear you.
   Nothing is recorded or uploaded." CTA: **Enable microphone** → triggers the system prompt.
   Card shows a live ✓ when granted (spring pop).
3. **Accessibility (priming, then Settings)** — "So your words land in any app, Screamm needs
   Accessibility." CTA: **Open Settings**. Poll `AXIsProcessTrusted()`; flip to ✓ when granted.
4. **Try it (the magic moment)** — "Hold **Right ⌘** and say anything." Live: when the first
   successful dictation lands, fire a small celebration and auto-advance. CTA: **Start using Screamm**.

Principles: value-first, no account, deferrable, warm copy, a light "commitment" beat on the
last card. Personality comes from copy + the animated pill, not a commissioned mascot (mascot = open question).

## 2) Streak + stats — a menu-bar popover

Menu bar shows the streak inline (e.g. `🔥 6`). Clicking opens a popover/panel:

- **Streak header:** flame + big number + "day streak", week row (S M T W T F S) with filled
  flames/checks for active days, encouraging line ("6 days — you're on a roll").
- **Metrics grid** (Letterboxd-style, big numbers): Words dictated (lifetime) · Time saved (est) · Days used.
- **Time-saved comparison** (Brick-style): "≈ 3.1 hrs saved — about a workday you got back."
  Honest estimate, labeled `~est` (formula in Data model).
- **7-day sparkline** of words/day (optional, phase 3).
- Footer: "All local. Nothing leaves your Mac."

## 3) Celebrations + micro-rewards

Celebrations are **tiered** (design-review decision) — escalating reward without spamming:

- **Micro-reward (every success):** when a dictation lands, the pill does a quick success
  bounce + brief ✓/green flash before hiding. Optional subtle sound (default OFF — respect the
  menu-bar quiet). This tiny beat is the core Duolingo trick.
- **Big milestones only** (first dictation, 1,000 / 10,000 words, 7- and 30-day streaks): a
  **compact confetti burst around a badge, near the pill at bottom-center** (NOT full-screen —
  it's a background utility), one CTA ("Nice"), auto-dismiss. Tasteful, never blocks typing.
- Under reduced-motion, both degrade to a static badge / cross-fade (see Accessibility).

## Data model (local-only)

`StatsStore` (ScreammKit), persisted to `~/Library/Application Support/Screamm/stats.json` (Codable):
- `schemaVersion` (for future migration), `totalWords`, `totalDictations`,
  `perDay: [YYYY-MM-DD: Int]`, `currentStreak`, `longestStreak`, `lastActiveDay`,
  `milestonesReached: Set<String>`.
- `recordDictation(wordCount:, at:)` → updates counts; streak logic uses `Calendar.current`
  day comparison: same day = no streak change; last-active == the day before `at` = streak+1;
  gap = reset to 1. Returns any newly-reached `Milestone`. `at`/calendar injectable for tests.
- **Corrupt / missing file:** decode failure → back up the bad file (`stats.json.bak`) and start
  from empty; never crash. Missing file → empty store.
- **Time saved** (honest estimate, labeled est): `wordsTyped/40wpm − wordsSpoken/150wpm`, i.e.
  ~ `totalWords × (1/40 − 1/150)` minutes. Tune; show as approximate.
- Privacy: never leaves disk; no network; user can reset stats.

## Architecture (where it slots in) — hardened in eng review

- **ScreammKit `StatsRecording` protocol** (new seam, matches `Transcribing`/`TextInjecting`):
  `recordDictation(wordCount:, at:) -> Milestone?`. `StatsStore` implements it.
- **`RecordingCoordinator`** takes an injected `StatsRecording?`. On successful injection it
  calls `stats?.recordDictation(...)`; if a `Milestone` comes back, it emits a new
  **`onMilestone`** hook (alongside existing `onStateChange`/`onError`). Also a **`onSuccess`**
  hook for the micro-reward. Keeps record-on-success in one tested place; testable with a fake.
- **`StatsStore`** (ScreammKit): in-memory model on main; **day math via `Calendar.current`
  `startOfDay(for:)`** (never string-compare dates — timezone/DST safe); persistence to
  `~/Library/Application Support/Screamm/stats.json` via **atomic write** (write temp + rename)
  on a **background queue** so the main thread never blocks on disk. Injectable `now`/`calendar`
  for tests.
- **`WhisperKitTranscriber` publishes a `LoadState`** enum `{ idle, downloading(Double),
  warming, ready, failed(Error) }`, always delivered **on the main thread** (SwiftUI observes
  it). **Two-step load:** call `WhisperKit.download(...progressCallback:)` first for a REAL
  percentage, THEN construct the transcriber from the downloaded model (the single-call init
  gives no progress). `AppDelegate.bootstrap()`, onboarding card 4, and the menu bar observe it.
  Onboarding kicks the load off on card 1. **Finishing onboarding is never gated on the
  download** — only the optional "try it" waits for `.ready`; "Start using Screamm" always works.
- **Screamm (app):** `OnboardingWindowController` + SwiftUI cards; `StatsPanel` (SwiftUI in an
  `NSPopover` anchored to the status item); `CelebrationController` (reuses the `OverlayController`
  `NSPanel` pattern, **reduced-motion aware**); success bounce added to `WaveformModel`/`OverlayController`.
- **`MenuBarController`:** left-click the status item opens the **stats popover** (streak +
  metrics), with a footer row for **Settings + Quit** inside it; a minimal right-click NSMenu
  stays as a fallback. Status item shows `🔥 <streak>` when a streak is active.
- **First-run:** `onboardingCompleted` flag in `UserDefaults`; `AppDelegate` shows onboarding on launch if unset.

## Animation spec

- Onboarding card transitions: slide + fade, `spring(response: 0.35, damping: 0.7)`.
- Permission granted ✓: spring scale pop.
- Success micro-reward: pill scale-bounce (1.0→1.12→1.0) + brief ✓ tint, <0.3s.
- Milestone: confetti burst (SwiftUI Canvas particles or TimelineView) + badge scale-in, ≤1.2s, dismissable.
- Everything spring, ≤0.4s except confetti, never blocks the user's task.

## Scope (phased, ship in order)

- **Phase 1 (core value):** `StatsStore` + record on dictation + success micro-reward pulse +
  Stats popover (streak + metrics + time-saved). This alone adds the retention hook.
- **Phase 2:** Onboarding window (permission priming + try-it magic moment).
- **Phase 3:** Milestone confetti/badges + 7-day sparkline + optional success sound.

## Test plan

- `StatsStore` (Swift Testing): consecutive-day streak increment; same-day no double-count;
  gap resets to 1; longest-streak tracking; milestone fires once and only once; word count;
  time-saved calc; persistence round-trip (encode/decode). `today` injected.
- Onboarding, celebration, popover = manual dogfood (UI).

## Eng-review hardening (macOS footguns — from outside voice)

- **StatsStore persistence:** the persisted model is a **struct**; `StatsStore` snapshots it on
  main and hands the copy to a **serial background queue** that does `Data.write(.atomic)` (after
  ensuring `~/Library/Application Support/Screamm/` exists). Flush **synchronously in
  `applicationWillTerminate`** so a quit-from-popover mid-write can't lose data.
- **Streak math:** compute "the day before" with `calendar.date(byAdding: .day, value: -1, ...)`
  + `isDate(inSameDayAs:)` — never 86400s arithmetic (DST). Guard `at < lastActiveDay`
  (clock set backwards) so the streak can't freeze. `perDay` keys are local days (accepted).
- **Menu-bar click:** don't set `statusItem.menu`; give the button one action and branch on
  `NSApp.currentEvent` (left → popover, right → minimal menu). Popover is `.transient`
  (outside-click dismiss); call `NSApp.activate(ignoringOtherApps: true)` before showing it or
  its SwiftUI buttons won't receive events (accessory app).
- **Onboarding window:** flip `NSApp.setActivationPolicy(.regular)` while onboarding is open
  (so the window can become key + accept Tab/Return/Esc), then back to `.accessory` on finish.
  `makeKeyAndOrderFront`. (Dock icon appears during onboarding only — acceptable.)
- **Celebration panel:** a **separate `.nonactivatingPanel`** (NOT the click-through waveform
  panel) so it never steals focus mid-typing. Milestone celebration is **click-through +
  auto-dismiss, no button** (dropped the "Nice" CTA — simpler, never blocks typing).
- **Celebration precedence:** during onboarding, **card 4 owns the celebration**; suppress the
  first-dictation milestone + micro-reward there so nothing triple-fires. The "first dictation"
  milestone fires on the first post-onboarding dictation instead.
- **Onboarding completion:** Esc / "Maybe later" / finishing ALL set `onboardingCompleted`.
- **Reduced motion:** single source — SwiftUI `@Environment(\.accessibilityReduceMotion)`;
  observe changes for a live toggle.
- **Status item:** SF Symbol **flame (template image)** + a monospaced-digit number, not the
  🔥 emoji (emoji ignores template tinting and jitters width).

## Resolved in design review

- **Celebrations:** tiered (micro near-pill every success; compact confetti+badge near pill
  for big milestones only; reduced-motion degrades to static).
- **Onboarding vs model download:** download starts on card 1 (background); card 4 gates with a
  "Warming up" state.
- **Mascot:** deferred — the animated pill is the character for v0.2.

## Open questions (still)

1. **Success sound** default on or off? Lean OFF (opt-in) for a menu-bar tool.
2. **Time-saved formula** — needs an honest, defensible assumption; always label `~est`.
3. **Streak freeze / "pause & preserve"** (Numo pattern) — kind loss-aversion. Defer to later.
4. Stats surface: `NSPopover` from the status item vs a small window. Lean popover.

## Interaction states (added in design review)

| Surface | Empty / first-run | Loading | Error / denied | Success |
|---|---|---|---|---|
| Stats popover | Day 1: no "0" wall. Show "Say your first words to start your streak 🔥" + the flame outline. Metrics show "—" with a friendly nudge. | n/a (reads local file, instant) | Stats file unreadable → rebuild from empty, never crash | Streak/metrics animate up on open (respect reduced-motion) |
| Onboarding card 2 (mic) | — | — | Denied → card stays, copy shifts to "Screamm can't hear you yet" + "Open Settings" button + retry | ✓ pops when granted |
| Onboarding card 3 (accessibility) | — | Polling AXIsProcessTrusted every ~1s | Not granted → "Open Settings" + live status "waiting…" | ✓ pops, auto-advance |
| Onboarding card 4 (try it) | Model still downloading → "Warming up the engine… ~30s" with progress; the CTA is disabled until ready, hotkey hint dimmed | Downloading model | Download failed → "Couldn't download the model" + Retry + manual-import link | First successful dictation → celebrate + auto-advance |
| Milestone celebration | — | — | — | Confetti + badge + one CTA, auto-dismiss |

## User journey / emotional arc

| Step | User does | User feels | Design supports it |
|---|---|---|---|
| First launch | Sees welcome card | Curious, slightly wary of a mic tool | Warm copy, "100% on your Mac" up front, no account ask |
| Grant mic/AX | Clicks through priming | Mild friction | Value framed before each system dialog; ✓ pop rewards each grant |
| Try it (card 4) | Holds Right ⌘, speaks | Nervous → delighted | The pill reacts live; text lands; a celebration confirms "it worked" |
| Day 2–6 | Opens stats from menu bar | Pride, momentum | Streak flame grows, "you're on a roll", time-saved framed as a win |
| Hits a milestone | Keeps dictating | Small joy | Tasteful confetti + badge, never blocking |

Time horizons: 5-sec (the pill + orange = "this is alive and mine"), 5-min (it just works, no setup), 5-year (streak/stats make it a daily habit, honestly).

## Design tokens (extends DESIGN.md — concrete numbers)

- **Type ramp (SF Rounded / `ui-rounded`):** Display 44/800, Title 26/800, Headline 17/700, Body 15/600, Caption 12–13/700 (labels UPPERCASE, tracking +0.03em).
- **Spacing scale:** 4, 8, 12, 16, 20, 24, 32 (use these, no arbitrary values).
- **Radii:** pill/capsule = full; cards 20–24; inner chips 14; buttons 16.
- **Colors:** brand `#F48C02`, brand-deep `#D67602`, tint bg `#FFF4E6`, ink `#1c1c1e`, muted `#8a8a8e`, hairline `rgba(0,0,0,.08)`. White content on brand.
- **Elevation:** cards `0 18px 50px rgba(0,0,0,.18)`; brand button gets a 6px solid brand-deep "bottom" (Duolingo tactile press).
- **Light/Dark:** define both. Dark popover = `#1c1c1e` card, brand stays, tint bg → `rgba(244,140,2,.14)`.

## Accessibility & reduced motion (non-negotiable)

- **Reduced motion:** if `NSWorkspace.shared.accessibilityDisplayShouldReduceMotion` is true, replace ALL spring/confetti/scale with a simple cross-fade (≤0.15s); the milestone "confetti" becomes a static badge. Never animate the waveform bars beyond a gentle opacity if reduce-motion is on.
- **Keyboard:** onboarding fully keyboard-navigable — Tab/Return advances, Esc = "Maybe later". Visible focus ring on the CTA.
- **VoiceOver:** every card has a heading + the CTA is labeled; the stats popover reads "6 day streak, 24,801 words dictated, about 3.1 hours saved". The waveform pill is decorative → `accessibilityHidden`.
- **Contrast:** white on `#F48C02` is ~2.9:1 — OK for large/bold ≥18pt but NOT for body. Body/labels use ink/muted on white, never white-on-orange at small sizes. Verify every pairing ≥4.5:1 (large ≥3:1).
- **Touch/click targets:** ≥44px for the CTA and menu-bar controls.
- **No color-only meaning:** streak days use a ✓ glyph, not just fill color.

## Approved mockup

Directional HTML mockup (brand-accurate, not the exact SwiftUI):
`~/.gstack/projects/screamm.ai/designs/onboarding-stats-20260910/mockup.html`. Real visual
references: the Mobbin links in "Real references" above.

## Non-negotiables (from DESIGN.md)

Local-only stats. No telemetry, no accounts, no network beyond model download. Reward, never
manipulate — no fake urgency, no guilt. Privacy is the brand.

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 0 | — | — |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 1 | CLEAR | 9 issues, 0 critical gaps |
| Design Review | `/plan-design-review` | UI/UX gaps | 1 | CLEAR | score 6/10 → 9/10, 6 decisions |
| Outside Voice | eng-review | Independent challenge (Claude) | 1 | issues_found | 7 macOS footguns, all folded in |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | — |

- **CROSS-MODEL:** outside voice challenged the LoadState-progress decision (→ two-step
  WhisperKit.download for real %) and surfaced 6 accessory-app/threading footguns, all folded.
- **UNRESOLVED:** 0
- **VERDICT:** DESIGN + ENG CLEARED — architecture locked (StatsStore threading + streak
  correctness + persistence, LoadState two-step, accessory-app popover/window, celebration
  panel), StatsStore fully test-spec'd. Ready to implement Phase 1.
