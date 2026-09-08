# Engine Spike — go/no-go gate

Throwaway CLI. Answers one question before we build any UI:
**is warm large-v3-turbo decode fast enough on this Mac to feel instant?**

Design-doc gate: **warm decode of a ~10s clip ≤ 2s = GO.**

## Run it

> ⚠️ On Swift 6.4 with only Command Line Tools installed, you must pass
> `--build-system native` (the new default XCBuild backend needs full Xcode).

```bash
# builds (already verified compiling) + downloads the turbo model on first run (~600MB-1.5GB)
swift run --build-system native ScreammSpike sample.aiff
```

First run downloads the CoreML model from HuggingFace, so it'll pause once. After that:

```bash
# the real test — record YOUR voice, ~10 seconds of natural speech:
say -o mytest.aiff "…or record yourself in Voice Memos and export…"
swift run --build-system native ScreammSpike mytest.aiff
```

The tool prints:
- `cold load` — model load + ANE compile (one-time per launch)
- `warm decode` — **the number that decides the project**

## If the model name errors

```bash
swift run --build-system native ScreammSpike --list-models
# then pass one:
swift run --build-system native ScreammSpike sample.aiff --model <id>
```

## What "GO" means

- **≤ 2s warm** → local turbo is fast enough. Proceed to build the app (step 0 in the
  design doc: git ✓ done, self-signed cert, then AudioRecorder → Injector → HotkeyManager).
- **> 2s warm** → try a smaller model, or rethink turbo-only before investing in UI.

This whole `Sources/ScreammSpike/` + `Package.swift` gets deleted once it answers the
question. It is not the app.
