# Screamm.ai — Design System

The source of truth for Screamm's look, feel, and UX principles. Inspired by Duolingo:
one bold brand color, chunky rounded shapes, white-on-color contrast, playful spring
motion, and a friendly, low-friction, reward-driven experience.

## Brand

| Token | Value | Use |
|---|---|---|
| Brand orange | `#F48C02` | Primary — the pill, key buttons, accents |
| Brand deep | `#D67602` | Pressed / "thinking" state of brand elements |
| Content | `#FFFFFF` | Text/icons/bars ON brand color (high contrast) |
| Ink | near-black | Text on light surfaces |

- **White on color.** Content sits white on the orange, like Duolingo's buttons. High contrast, confident.
- **Chunky + rounded.** Capsules and large corner radii (16–20pt). Nothing sharp or corporate.
- **Typography:** SF Rounded for a friendly voice (system rounded), bold weights for emphasis.

## Motion

- **Spring, not linear.** Appearances pop (`spring(response: ~0.32, damping: ~0.62)`). The
  pill morphs in like the Dynamic Island.
- **Micro-rewards.** Every success gets a tiny, satisfying beat (subtle animation; optional
  sound). This is Duolingo's core retention trick — make the win feel good.
- Keep motion fast (<0.35s) and never in the way of the user's actual task.

## Voice & personality

Encouraging, warm, plainspoken. Celebrates the user, never scolds. Permission prompts are
friendly and explain the value ("so your words land wherever you type"), never scary.

## Duolingo principles → Screamm

1. **Value-first onboarding.** Get the user dictating in under 60 seconds. No account (there
   isn't one). Explain each permission warmly, in context, right when it's needed — not a wall
   of setup up front.
2. **Retention through gentle streaks + stats.** Track, locally and privately: words dictated,
   estimated time saved, and a day streak. Surface it in the menu ("🔥 6-day streak · 24,801
   words · ~3.1 hrs saved"). Positive reinforcement, never guilt. No dark patterns — this is a
   utility, honesty is the brand.
3. **Celebrate wins.** A subtle success cue after a good transcription. Milestones (first
   1,000 words, first week) get a small, tasteful celebration.
4. **Reduce every friction.** Sensible defaults, one-key dictation, nothing to configure to
   start. Settings are optional depth, not required setup.

## Components

- **The pill (built):** brand-orange `Capsule`, white waveform bars, spring pop, orange glow,
  deepens while transcribing. Bottom-center of screen.
- **Menu bar (built):** status glyph + status line. Will grow to show streak/stats.
- **Onboarding (planned):** 2–3 friendly cards — welcome → grant mic/accessibility in context
  → "hold Right ⌘ and talk" with a live demo.
- **Stats / streak (planned):** local-only counters in the menu; milestone celebrations.

## Non-negotiables

- **Privacy is the brand.** Stats and streaks are computed and stored **locally only**. No
  telemetry, no accounts, no network beyond the one-time model download.
- **Delight without dark patterns.** Reward, don't manipulate. No fake urgency, no guilt.
