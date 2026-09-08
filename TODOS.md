# Screamm.ai — TODOS

## Deferred (post-v0.1)

### Idle model unload (memory vs latency)
- **What:** After N minutes idle, unload the resident Whisper model to free memory; reload on next dictation.
- **Why:** The warm large-v3-turbo model holds ~1.5GB in unified memory continuously. On an 8GB Mac that's meaningful pressure.
- **Pros:** Frees ~1.5GB when not dictating; friendlier on low-RAM Macs.
- **Cons:** First dictation after idle pays cold-load + ANE re-JIT latency (the exact thing v0.1 designs away by keeping warm).
- **Context:** v0.1 keeps the model always warm (correct default for a fast dictation tool). This TODO adds a *configurable* idle-unload timer, default OFF on 16GB+, optionally ON for low-RAM Macs. Surfaced in the eng-review performance pass.
- **Depends on:** Transcriber warm-load implementation (v0.1) + a Settings surface (v0.2).
