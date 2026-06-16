# Chapter 11 — Voice & Parakeet (Premium Sovereign Stack)

**Public-safe:** the full “undressing” of how family voice works — what we **dropped**, what we **promoted**, and how routing picks quality vs speed.

---

## Operator intent (why we changed voice)

Bootstrap voice used **Kokoro** (small ONNX TTS via speaches on DGX CPU) and **Fish Speech** container naming — enough to prove STT→LLM→TTS wiring, but:

- Sounded **novice, slow, robotic** — not covenant with `data/nephew-soul.md`  
- Did not match **Grok-class** natural talk-and-reply the board wanted  
- DGX CPU Kokoro was **never the end state** — it was vanilla scaffolding  

**Decision (Plan 0201 / 0202):** demote Kokoro to **fallback tier**; promote **Holler** (Qwen3-TTS) on M5 as daily premium; add **F5-TTS** + **NeMo Riva** on DGX for clone/prime quality.

*(If you said “Komodo” or “Caldo” in conversation — the stack name is **Kokoro**; that is what we stepped down from speaking roles.)*

---

## Engine tiers today

Canonical registry: `marvelousempire/nephew` → `data/voice-config.json`

| Engine | Tier | Route | Role |
|---|---|---|---|
| **Holler** (Qwen3-TTS) | **premium** | M5 edge | Daily Jarvis — Grok-like responsiveness, natural prosody |
| **F5-TTS** | premium | DGX | Operator voice **clone** from reference WAV |
| **NeMo Riva** | premium | DGX | NVIDIA high-fidelity gateway (prime flag) |
| **Spark-TTS** | premium (planned) | DGX | Emotional synthesis — future slot |
| **Kokoro M5 local** | standard / interim | M5 | Only when Python 3.12+ missing for Holler |
| **Kokoro DGX / speaches** | **fallback** | DGX | Emergency — hidden from persona picker |
| **Browser speech** | last resort | client | Offline degrade |

**Personas (premium group):** Jarvis (kit voice), Nephew (nora), Board (oliver) — all bound to **Holler**, not Kokoro presets.

---

## Routing algorithm (tower-api)

```text
POST /api/v1/voice/tts
    ↓
Resolve route: auto | m5 | dgx (header + health)
    ↓
If m5 route → Holler gateway (premium)
If clone voice + F5 healthy → F5-TTS with ~/.nephew/voice-refs/operator.wav
If prime flag + Riva healthy → NeMo Riva
Else F5 with ref → else Riva → else Kokoro fallback
    ↓
Stream audio to Pockit voice-pad / iMessage bridge / CT play button
```

STT path: M5 **faster-whisper** when on edge route; DGX **whisper/speaches** when on brain route. Multipart mic upload fixed so WebM from browser no longer 422s.

---

## Parakeet — the Pockit voice cassette

Parakeet is **not** a standalone app — it is a **Pockit pad cassette**:

| Concept | Value |
|---|---|
| Cassette id | `voice` |
| Operator URL | `http://pockit.localhost/#/c/voice` |
| Surface type | `settings.surface.type: voice` |
| Boot script | `voice-pad.js` |
| Parent console | `pockit` |

**Non-vanilla UX features shipped:**

- Real Web Audio **visualizer** (energy-reactive bars)  
- **Haptics** on speak / think / error (vibrate API)  
- **Prefetch TTS queue** — clause/chunk streaming while LLM still generating (Grok-bar pattern)  
- Route picker: Auto / M5 / DGX  
- Engine label in status: “Holler · M5 premium” vs fallback warnings  
- `pumpTurn` telemetry into live knowledge fabric  

Verify: `make cassette-line CHECK=voice` — **all gates green** as of Nephew v1.79.42 (2026-06-15): manifest registered, `settings.surface` validates via `cassette-surface.schema.json`, door + resolve-surface pass.

---

## What we demoted (explicit)

| Before (vanilla) | After (sovereign premium) |
|---|---|
| Kokoro as primary TTS | Holler on M5 for personas |
| Fish Speech container → speaches Kokoro backend | Named legacy; F5/Riva for quality path |
| Single DGX CPU TTS | Hybrid M5 fast + DGX clone/prime |
| Robotic preset voices in picker | Premium persona group only; Kokoro in `fallback_presets` hidden |
| One-shot TTS after full LLM | Sentence-level streaming + prefetch queue |

Fish Speech **native aarch64** remains queued — when it ships, swap backend URL without changing Parakeet UX.

---

## Operator clone (“sound like me”)

1. Record ~90s reference: `bash scripts/record-voice-ref.sh`  
2. Saves to `~/.nephew/voice-refs/operator.wav` (gitignored)  
3. F5-TTS on DGX uses ref for clone slot  
4. Consent flag in voice-config — family law  

Until ref exists, clone slot falls back to Jarvis Holler persona.

---

## Reboot-safe M5 edge (Plan 0202)

Problem: Holler stack died on reboot → voice pad fell back to robotic DGX Kokoro.

Fix stack:

- `m5-voice-edge-daemon.sh` at boot  
- `m5-voice-supervisor.sh` restarts STT + Holler backend + gateway  
- `make voice-launchagent` installs LaunchAgent with PATH for uv Python 3.13  
- Kokoro M5 server **only** as interim if Holler cannot start  

Boss move once per Mac: **`make voice-launchagent`**

Holler requires **Python 3.12+** — `bootstrap-python313-m5.sh` or `brew install python@3.13`.

---

## Channels using the same stack

| Channel | Voice path |
|---|---|
| Pockit Parakeet pad | tower-api voice routes |
| Control Tower hello | chat + 🔊 play button |
| iMessage bridge | STT → Hermes → TTS reply audio |
| `m5-voice-loop.py` CLI | Interactive push-to-talk loop |
| Future iOS VoiceIO | Same tower-api contract |

---

## Health & evaluation

```bash
# From nephew repo on operator Mac (local tower proxy)
curl -s http://127.0.0.1:8088/api/v1/voice/health | jq .

node scripts/voice-fast-path.mjs --route auto --smoke-tts
node scripts/eval-voice-engines.mjs
make cassette-line CHECK=voice
```

Expect: `route_preferred: m5`, `m5_edge.ok: true`, `tts.engine: holler` when edge healthy.

---

## Enterprise audit extensions (GitHub `voice-security-audit-2026-06`)

Merged from enterprise agents — **planning / roadmap**, not all live on fleet yet:

| Topic | Chapter | Status |
|---|---|---|
| Redis STM + semantic voice cache | [21-redis-persistence.md](./21-redis-persistence.md) | Compose stub in `infrastructure/redis/` |
| Zero-trust Caddy mTLS doors | [19-zero-trust-caddy-doors.md](./19-zero-trust-caddy-doors.md) | Planning — live doors today use `make doors` gateway |
| iPhone 17 / iPad Pro surfaces | [20-mobile-surfaces-ios17.md](./20-mobile-surfaces-ios17.md) | Planning |
| ANE optimization detail | [24-apple-neural-engine-voice-optimization.md](./24-apple-neural-engine-voice-optimization.md) | Stub — expand |
| Diarization / SpeakerKit / WeSpeaker | [00-system-blueprint-audit-2026-06.md](./00-system-blueprint-audit-2026-06.md) | Roadmap |

---

## Related

- [10-m5-max-sovereign-edge.md](./10-m5-max-sovereign-edge.md) — M5 daemon chain  
- [09-talking-to-your-machines.md](./09-talking-to-your-machines.md) — Jarvis vs Visual naming  
- Nephew: `docs/pockit/Parakeet-Voice-Cassette-Vanilla.md`, `plans/0201`, `plans/0202`, `docs/runbooks/m5-voice-loop.md`
