# Chapter 10 — M5 Max Sovereign Edge (Nephew Max)

**Public-safe:** how the MacBook M5 Max is built as a **non-vanilla personal Jarvis** — complementary to DGX, not a thin client.

---

## Nephew Max in one sentence

**DGX Spark = deep brain** (vLLM, heavy RAG, concurrent agents, DGX premium voice clones).  
**M5 Max = edge Jarvis** (ANE-friendly dev, low-latency voice, Obsidian front-end, Pockit gateway, failover when away or when DGX is busy).

Both share the **Live Knowledge Fabric** — same cassettes, same NEPHEW.md rules, same embedding model family, same Micro Slice discipline.

---

## What we deliberately built on the M5 (not stock macOS)

| Customization | Purpose |
|---|---|
| **M5 voice edge daemon** | Reboot-safe Holler STT/TTS stack; supervisor restarts on crash |
| **Hardware auto-detect** | Writes `m5-hardware.json` — chip, RAM, cores, TTS priority list |
| **LaunchAgent KeepAlive** | `make voice-launchagent` once — voice survives reboot |
| **Python 3.12+ bootstrap** | uv / Homebrew path for Holler (Qwen3-TTS) — not system Python 3.9 |
| **Local metrics stub** | Loopback hardware JSON for voice-pad status badges |
| **tower-api on Mac** | Proxies voice/chat to DGX; M5 route when edge healthy |
| **Obsidian golden profile** | Checked-in theme + plugins + CSS — family parity on fresh Mac |
| **Pockit gateway host** | Doors, suite bar, Parakeet pad run here during dev |
| **OLLAMA_HOST handoff** | Local Ollama for fast turns; DGX for heavy inference |
| **WireGuard peer** | Same mesh as DGX — vault mounts, forge push, remote doors |
| **Native Pockit.app** | Swift launcher with Po icon — Notification Center identity (not AppleScript applet) |

This is **synthesized infrastructure** — scripts, launchd, manifests, and Pockit surfaces wired together, not a default Ollama install.

---

## M5 edge services boot chain

```text
Login / reboot
    ↓
LaunchAgent (voice-launchagent)
    ↓
m5-voice-edge-daemon.sh
    ↓
m5-edge-services.sh
    ├── detect_hardware → ~/.nephew/run/m5-voice/m5-hardware.json
    ├── bootstrap-python313-m5.sh (Holler prerequisite)
    ├── install-m5-voice-edge.sh
    │     ├── faster-whisper STT (local)
    │     ├── Holler backend (premium TTS) when Python OK
    │     └── Kokoro M5 interim if Holler unavailable
    └── m5-holler-tts-gateway.mjs (OpenAI-compatible TTS API)
    ↓
m5-voice-supervisor.sh (watchdog restart loop)
```

Operator commands (nephew repo):

```bash
make voice-launchagent   # once per Mac — KeepAlive
make m5-edge-up          # manual bring-up
make ensure-voice        # best-effort edge + health
make m5-voice-loop       # interactive CLI talk loop
```

---

## Hybrid routing (Auto / M5 / DGX)

Parakeet Voice Pad exposes three modes — mirrored in tower-api:

| Mode | When | Path |
|---|---|---|
| **Auto** | Default | M5 edge if healthy → else DGX brain |
| **M5 edge** | Low latency, Grok-class Holler | Local STT + Holler TTS + optional fast LLM |
| **DGX brain** | Clones, prime quality, heavy RAG | DGX Whisper + F5-TTS / NeMo Riva + full retrieve |

Status badge target copy: **SOVEREIGN • M5 MAX + DGX • MICRO SLICES RAG**

---

## Obsidian + vault on M5

| Piece | Role |
|---|---|
| NAS mount | Historia volume → sovereign vault path |
| Visual-Home.md | Landing note — graphs, links, orchestra HUD |
| Golden profile apply | AnuPpuccin + jarvis-sovereign.css + plugin set |
| LiveSync | CouchDB bridge (when operator completes wizard) |
| Vault pumps | Grok sessions, git, Matrix, Pockit activity → Micro Slices |

Agents run `make visual-obsidian` — never manual vault hunting.

---

## Dev workstation integration

- **Primary Cursor/Claude host** for nephew monorepo  
- **Same rules as production agents** — dev and family paths share soul + guardrails (Plan 0040 unification)  
- **ANE path** (roadmap): local Whisper CoreML, MLX embeddings for disconnected private Jarvis  
- **One-command remote exec** to DGX for docker, reindex, deploy  

---

## Failover story

When DGX unreachable:

1. M5 local Ollama + light RAG subset (or cached slices)  
2. M5 Holler/Kokoro voice loop still works via edge  
3. Obsidian vault on NAS mount — human can still read/write  
4. On reconnect — backfill pumps sync new slices to central Qdrant  

---

## Build checklist (operator)

1. Join WireGuard mesh  
2. Clone nephew to standard developer path; `make hooks`  
3. `make voice-launchagent`  
4. `make visual-obsidian-full` after NAS mount  
5. `make doors` + `make pockit`  
6. Hard refresh Pockit voice pad — confirm Holler engine in status  
7. Optional: `bash scripts/record-voice-ref.sh` for F5 operator clone on DGX  

Full spec mirror: `marvelousempire/nephew` → `docs/infrastructure/m5-max-sovereign-jarvis-build.md`

---

## Related

- [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md) — Kokoro → Holler upgrade story  
- [12-pockit-non-vanilla-surfaces.md](./12-pockit-non-vanilla-surfaces.md) — UI layer  
- [09-talking-to-your-machines.md](./09-talking-to-your-machines.md) — all comms channels
