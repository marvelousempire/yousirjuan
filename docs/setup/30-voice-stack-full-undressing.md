# Chapter 30 — Super Rick Voice Stack (Full Undressing)

**Public-safe** · the complete configured stack as deployed on the Family Office — every service, model, port, tweak, and covenant.

**Canonical technical copy (mirrored):** `marvelousempire/standard-voice-stack` → `understandings/FULL-STACK-UNDRESSING.md`  
**Runtime owner:** `marvelousempire/nephew` → `data/voice-config.json`, `src/voice/`, tower-api

**Last verified:** Tuesday, June 30, 2026 · Nephew Pockit **v1.91.48** · SVS `main` @ `0ae48eb`

Complements [Chapter 11 — Parakeet premium](./11-voice-parakeet-premium-stack.md) and [Chapter 28 — Voice containers](./28-voice-containers-whisper-fish-speech.md) with the **June 2026** Presence-orb era truth.

---

## Platform lens — what You-Sir Juan ships vs what Nephew runs

| Layer | You-Sir Juan platform | Family Office live stack |
|-------|----------------------|---------------------------|
| Philosophy | Voice as human interface ([`ai-skills/tts-and-speech-systems.md`](../../ai-skills/tts-and-speech-systems.md)) | **Super Rick** — sovereign, premium, present |
| Default privacy | Local STT/TTS first | **Zero cloud** — `quality_covenant` enforces |
| Hardware map | [`ai-skills/model-to-hardware-mapping.md`](../../ai-skills/model-to-hardware-mapping.md) | M5 Max edge + DGX Spark GB10 |
| Product surface | Family interface vision | Pockit + **The Presence** orb |
| Config registry | Platform docs | Nephew `data/voice-config.json` (schema v2) |

This chapter is the **operator undressing** — not marketing copy.

---

## 1. Surfaces you open

| What | URL |
|------|-----|
| **The Presence** (default voice door) | http://voice.localhost/ |
| Pockit voice cassette (iframe orb) | http://pockit.localhost/#/c/voice-cassette |
| Super Rick status LEDs | http://voice.localhost/super-rick |
| **Knowledge pad** (Brain A reindex UI) | http://pockit.localhost/#/c/knowledge |
| Family corpus search (SME) | http://search.localhost/ |
| Voice API (JSON only) | http://127.0.0.1:8088/api/v1/voice/* |

Run `make doors` once per Mac (sudo) so `.localhost` URLs need no port.

---

## 2. Software inventory

### Mac M5 edge (daily operator path)

| Component | Port | Package / script |
|-----------|------|------------------|
| tower-api | 8088 | Nephew `bin/nephew-tower-api` |
| voice-console door | 8804 | `cassettes/product/voice-console/server.mjs` |
| The Presence UI | 8810 | Next.js 15 + Three.js r175 (`apps/super-rick-presence`) |
| Holler TTS (Qwen3-TTS 6-bit) | 7851 | `scripts/m5-edge-services.sh` |
| faster-whisper STT | 8767 | same |
| Redis STM | 6379 (tunnel) | `make ensure-redis-stm` |
| Local Ollama fast path | 11434 | `hermes-bridge.js` for Presence channel |

### DGX Spark (brain + premium DGX TTS)

| Component | Port | Notes |
|-----------|------|-------|
| Ollama `nephew:fast` | 11434 | Draft + swarmer models |
| vLLM Qwen3-32B-FP8 `nephew:prime` | 8003 | Double-pass audit |
| Whisper container | 8767 | STT when route=dgx |
| F5-TTS | 7860 | Voice clone |
| NeMo Riva | 9001 | DGX emotional primary |
| Kokoro / Fish | 7851 | **Fallback / ops only** |
| Higgs Audio V2 | 8095 | **Live** — Plan 0452 Ph 3–4 wired (`higgs-tts` on voice-config) |
| Qdrant + embed + reranker | 6333 / 9200 / 9201 | Grounded RAG · full reindex via Knowledge pad **`memory-fabric`** scope |

---

## 3. Models (names in config)

| Alias | Where | Role |
|-------|-------|------|
| `nephew:fast` | Ollama | Draft replies, emotion swarmer, fallback audit |
| `nephew:prime` | vLLM GB10 | Mandatory audit elevation (Qwen3-FP8) |
| Holler presets | M5 | kit, nora, oliver, joe, tessa, dakota, … |
| Kokoro presets | DGX fallback | 20+ voices — **not user-facing speak** |
| STT | faster-whisper `base.en` (M5) | COMP target Large-v3-Turbo not yet |
| Clone | F5 + `~/.nephew/voice-refs/` | Operator slot status: **no-refs** |

---

## 4. Configuration tweaks (`voice-config.json`)

All fields live in Nephew `data/voice-config.json`. Key operator toggles:

### Quality covenant (locked)

- No cloud TTS · no browser speech · no Kokoro user speak
- Text-only degrade when premium down
- Allowed speak engines: holler, f5-tts, nemo-riva, spark-tts

### Pipeline toggles

| Block | Notable values |
|-------|----------------|
| `double_pass` | mandatory, max_audit_ms **2000**, skip_on_cache_hit |
| `semantic_cache` | threshold **0.92**, ttl 1h, namespace `voice-fast` |
| `audio_cache` | ttl 1h, max 32 chunks |
| `emotion_swarmer` | 950ms cap, skip on fast/cache hit |
| `conversation_memory` | 40 turns, 24h ttl |
| `turn_taking` | VAD 0.5, silence 600ms, barge-in on |
| `speculative_decoding` | **inert** — do not enable without consumer |

### Pockit cassette settings (UI)

Defaults: orb surface, route auto, RAG fast, double-pass on, barge-in on, presence URL `http://voice.localhost/`.

Write path: Settings → Voice or Configurations Center; API `PATCH /api/v1/operator/config/voice-config`.

---

## 5. Turn flow (one sentence per stage)

```text
Mic → Whisper STT → VAD/turn-taking → semantic cache lookup → corpus retrieve (if grounded)
→ emotion swarmer (4× fast agents) → nephew:fast draft → nephew:prime audit (2s cap)
→ emotion TTS routing → Holler/F5/Riva → audio (+ streaming slice 2 pending)
```

---

## 6. The Presence — graphics stack

- **WebGPU path:** TSL volumetric SDF raymarch orb
- **WebGL path:** GLSL icosahedron + postprocessing bloom (Safari)
- **React:** R3F 9.x, framer-motion HUD
- **Voice:** `use-presence-turn-cycle.ts` → tower-api
- **Ops:** always start via `scripts/run-super-rick-presence.sh` (copies Next static assets)

HUD fix (Nephew Pockit v1.90.65+): persistent top bar; orb scaled to 0.72 so "Listening" / "Calm" stay readable.

---

## 7. LaunchAgents & boot ensure

| Label | Role |
|-------|------|
| `com.nephew.tower-api` | Voice API orchestrator |
| `com.nephew.super-rick-presence` | Orb at :8810 |
| M5 voice edge (Plan 0202) | Holler + STT KeepAlive |

Operator ritual: `make ensure-voice` or `make nephew` on a fresh Mac voice day.

---

## 8. Make targets (Nephew repo)

```bash
make ensure-voice              # full edge bootstrap
make ensure-m5-voice           # M5 Holler + STT
make ensure-dgx-voice          # DGX probes + heal
make ensure-voice-submodule    # standard-voice-stack via gitea-dgx (Spark-safe)
make memory-fabric-reindex     # full Brain A + vault (DGX; or Knowledge pad UI)
make smoke-voice-latency       # receipt JSON
make cassette-line CHECK=voice
make install-voice-app         # Desktop Voice.app
```

---

## 9. Latency truth (2026-06-25 smoke)

| Metric | p50 ms | Target |
|--------|--------|--------|
| Cached LLM turn | 27 | ✅ |
| Uncached turn | 16700 | fresh reasoning |
| TTS alone | 2419 | streaming slice 2 |
| Cached E2E | 2446 | ≤300 (audio cache) |

Receipt: voice-stack `receipts/2026-06-25-voice-latency-smoke.json`

---

## 10. Fleet documentation map

| Repo | What to read |
|------|--------------|
| **standard-voice-stack** | `understandings/FULL-STACK-UNDRESSING.md` (this chapter's twin) · `status/voice/2026-06-29-memory-fabric-reindex-knowledge-pad.md` |
| **nephew** | `docs/pockit/help/voice/*`, `data/voice-config.json`, Knowledge pad `knowledge-hud.js` |
| **search-my-engine** | `docs/family-corpus.md` — SME door `http://search.localhost/` |
| **intent-quality-super-rick** | Orb design standards |
| **yousirjuan** | This file + Chapters 11, 28 |

**Sync discipline:** Author voice understandings in **standard-voice-stack** first; mirror this chapter from `understandings/FULL-STACK-UNDRESSING.md` after each SVS merge (platform-safe framing only — no runtime secrets).

```bash
cd ~/Developer/standard-voice-stack && git pull --ff-only origin main
# Then diff/update this chapter from understandings/FULL-STACK-UNDRESSING.md
```

---

## 11. Boss Moves

1. **Doors fail** → `make doors` (sudo, once per Mac)
2. **Orb blank / Application error** → restart Presence script; hard-refresh browser
3. **Mic** → grant browser permission on http://voice.localhost/
4. **DGX voice down** → SSH `nephew-spark`, `docker ps`, `make ensure-dgx-voice` from Mac
5. **Record clone** → `make ensure-voice-ref` (interactive)

---

## Related chapters

- [11 — Parakeet premium stack](./11-voice-parakeet-premium-stack.md)
- [28 — Whisper / Fish containers](./28-voice-containers-whisper-fish-speech.md)
- [15 — Doors & Pockit navigation](./15-doors-cassettes-pockit-navigation.md)
- [10 — M5 Max sovereign edge](./10-m5-max-sovereign-edge.md)
- [06 — Retrieval & memory](./06-retrieval-and-memory.md)