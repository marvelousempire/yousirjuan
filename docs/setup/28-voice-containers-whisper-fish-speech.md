# Chapter 28 — Voice containers (Whisper, Fish Speech, M5 edge)

**Public-safe** · complements [Chapter 11 — Parakeet premium stack](./11-voice-parakeet-premium-stack.md)

---

## Two voice planes

| Plane | Host | Role |
|-------|------|------|
| **M5 edge (daily premium)** | FIVEMAC M5 Max | Holler TTS, faster-whisper STT, voice loop, Parakeet pad |
| **DGX brain (heavy / fallback)** | nephew-spark | Whisper container, Fish Speech / speaches, Hermes chat for voice routes |

**Jarvis = voice lane only.** **Visual = Obsidian.** Do not conflate.

---

## DGX containers (live fleet)

| Container | Port | Role |
|-----------|------|------|
| `nephew-whisper` | STT sidecar | Speech-to-text when route = dgx |
| `nephew-fish-speech` / speaches | `:8002` | Legacy TTS — **fallback tier** (demoted Plan 0201) |
| Hermes | `:8642` | LLM for voice-turn replies via tower-api |
| tower-api | `:8088` | `/api/v1/voice/tts`, `/api/v1/voice/stt`, chat adapter |

Verify on DGX:

```bash
ssh nephew-spark 'docker ps --format "{{.Names}} | {{.Status}}" | grep -E "whisper|fish|hermes|tower"'
```

---

## M5 edge (operator daily path)

| Service | Script / target |
|---------|-----------------|
| Holler (Qwen3-TTS) | `scripts/m5-edge-services.sh` |
| Voice LaunchAgent | `make voice-launchagent` |
| Voice loop probe | `make m5-voice-loop-probe` |
| Parakeet cassette | `http://pockit.localhost/#/c/voice` · `make cassette-line CHECK=voice` |

Registry: Nephew `data/voice-config.json` — premium = Holler on M5; Kokoro DGX = fallback only.

---

## Routing (tower-api)

```text
POST /api/v1/voice/tts
  → route: auto | m5 | dgx
  → m5: Holler premium
  → dgx: F5 clone → Riva → Kokoro fallback
STT: M5 faster-whisper (edge) or DGX whisper (brain)
```

All routes stay on **Family Office hardware** — no cloud TTS/STT APIs.

---

## Sovereign egress

Voice configs must not reference cloud speech APIs. Audit: `make sovereign-egress-audit` (Nephew repo).

---

## Boss Moves

1. First M5 voice day: `make ensure-m5-voice` or `make nephew` (full stack)
2. DGX voice unhealthy: SSH to Spark · `make family` · check whisper/fish containers
3. Parakeet pad silent: confirm Holler up · `make m5-voice-loop-probe`

Implementation owner: **Nephew repo** · Runbooks: `docs/runbooks/activate-messaging.md`, `docs/pockit/Parakeet-Voice-Cassette-Vanilla.md`.
