# iMac (Retina 4K, 21.5-inch, 2017) — You-Sir Juan OS Compatibility

## Machine specs

| Component | Spec | Notes |
|---|---|---|
| CPU | Intel Core i5, 3.4 GHz Quad-Core (Kaby Lake) | 4 cores / 4 threads, AVX2 support |
| GPU | Radeon Pro 560, 4 GB VRAM | AMD — no CUDA, no ROCm on macOS |
| RAM | 64 GB DDR4-2667 | Unofficial upgrade beyond Apple's 32 GB max — but recognized |
| OS | macOS Ventura 13.7.8 | Latest officially supported; Sonoma/Sequoia require OpenCore |
| Xcode max | Xcode 15.4 | Ventura cap — cannot build iPadOS 18 or visionOS 2 targets |

---

## How it fits the You-Sir Juan OS

**Tier:** BYO runtime node — full backend stack, web interface, light inference.

This machine runs the entire server-side of You-Sir Juan OS comfortably. The constraint is inference speed: no Apple Neural Engine, no CUDA. Ollama runs CPU-only on Intel. The 64 GB RAM is a genuine advantage — it allows larger quantized models to load fully in RAM where a machine with less memory would swap.

---

## What it can run — and how well

### ✅ Full capability

| Service | Port | Notes |
|---|---|---|
| Express API | 4000 | Runs natively — no Docker required, or via Docker |
| PostgreSQL | 5432 | Docker or native Homebrew install |
| Redis | 6379 | Docker or native |
| Qdrant | 6333 | Docker (x86_64 image) |
| Next.js web app | 3000 | `pnpm dev` or `pnpm start` — full web interface |
| Nginx | 80/443 | Reverse proxy, TLS, all standard routing |
| Kokoro TTS | 8880 | CPU mode — works, slightly slower than Apple Silicon |
| HomeKit bridge | 4002 | Node.js service — no hardware dependency |
| WireGuard | — | GL.iNet handles this; Mac is a client on the mesh |

### ✅ Ollama — with model selection guidance

Ollama runs on Intel Mac (x86_64, CPU-only). AVX2 instructions are present on Kaby Lake, which llama.cpp uses. The 64 GB RAM means models up to ~50 GB quantized can load fully without swapping.

| Model | RAM needed | Speed estimate | Verdict |
|---|---|---|---|
| `llama3.2:3b` Q4_K_M | ~2 GB | 8–15 tok/sec | ✅ **Recommended** — fast enough for voice turns |
| `llama3.1:8b` Q4_K_M | ~5 GB | 3–6 tok/sec | ✅ Usable — acceptable for non-time-critical turns |
| `mistral:7b` Q4_K_M | ~4 GB | 4–8 tok/sec | ✅ Good alternative to llama3.1:8b |
| `llama3.1:70b` Q4_K_M | ~40 GB | 0.5–1 tok/sec | ⚠️ Loads in RAM but too slow for real-time voice |
| `llama3.3:70b` | ~40 GB | 0.5–1 tok/sec | ❌ Not practical for interactive use |

**Set in `.env`:**
```
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2:3b
```

Why speed matters: a voice turn needs a response in under 3–4 seconds to feel natural. At 8–15 tok/sec, llama3.2:3b generates a 30-token reply in 2–4 seconds — right on the edge. At 3 tok/sec (8b models), a 30-token reply takes 10+ seconds — noticeable lag for voice.

### ✅ Web interface — full experience

The Next.js web app runs completely. All 7 routes work. Voice-first conversation works via the Web Speech API. The browser handles STT; Kokoro (Docker, CPU mode) handles TTS. Associate Agent paradigms render in full. WebAuthn passkey auth works in Chrome/Safari on Ventura.

The RealityKit 3D experience is iOS-only — the web interface renders the 2D paradigm version, which is the correct path for this machine.

### ⚠️ iOS/visionOS development — blocked on Ventura

| Target | Status | Reason |
|---|---|---|
| iPadOS 18 app (iOS simulator) | ❌ Cannot build | Requires Xcode 16, which requires macOS 14.5 Sonoma |
| visionOS 2 target | ❌ Cannot build | Same Xcode constraint |
| iPadOS 17 (older Xcode 15 target) | ⚠️ Limited | Could build an older iOS 17 version, but not the current app |

**Workaround:** OpenCore Legacy Patcher can run Sonoma on this iMac, which unlocks Xcode 16 and iOS 18 development. This is an advanced option — stable for many users but unsupported by Apple.

**Without OpenCore:** Use this machine as the runtime/server, and build iOS on a separate Apple Silicon Mac.

---

## Recommended role in a You-Sir Juan household

### Primary use: Always-on BYO runtime node

Run the full backend on this iMac. It is an excellent always-on server:
- iMac form factor: quiet, power-efficient enough for 24/7 operation
- 64 GB RAM: far more than the backend needs (Postgres + Redis + Qdrant + API + Node = ~4–8 GB typical)
- Remaining RAM available for Ollama model loading (~55 GB free for models)

### Interface: Web client on any browser

Any device on the network hits `http://<imac-ip>:3000` and gets the full web interface. Works on existing iPads, laptops, phones. No new hardware needed.

### Inference: Small models, real-time voice

Use `llama3.2:3b` for voice turns — fast enough for real-time interaction. Use `llama3.1:8b` or `mistral:7b` for background memory/summary tasks where latency matters less.

---

## What makes this machine stronger than it looks

**64 GB RAM is the secret weapon.** Most people would look at a 2017 Intel iMac and assume it's too slow for AI. The unofficial 64 GB upgrade changes the calculation:

- The entire `llama3.2:3b` model loads in ~2 GB and runs from RAM — no disk I/O during inference
- Multiple services (Postgres, Qdrant, Ollama, Node, Kokoro) all run simultaneously without memory pressure
- A Mac mini M4 Pro (48 GB) has faster per-token generation, but this iMac has more headroom for concurrent services

The honest comparison:
- Mac mini M4 Pro: ~3–5× faster tokens/sec, but same backend workload capability
- This iMac: slower inference, but capable backend server and comfortable for `llama3.2:3b` voice turns

---

## Docker setup for this machine

```bash
# Install Docker Desktop for Mac (Intel)
# https://docs.docker.com/desktop/setup/install/mac-install/
# Choose: Mac with Intel chip

# From repo root — starts all services
docker compose up -d

# Verify
docker ps
curl http://localhost:4000/health
curl http://localhost:11434/api/tags
```

All images in `docker-compose.yml` have x86_64 variants and will pull the correct architecture automatically.

---

## Quick capability summary

| Capability | Status |
|---|---|
| Backend API (Express) | ✅ Full |
| Web interface (Next.js) | ✅ Full |
| Associate Agent voice turns | ✅ With llama3.2:3b (2–4 sec response) |
| Private memory + Postgres | ✅ Full |
| Kokoro TTS | ✅ CPU mode |
| HomeKit bridge | ✅ Full |
| Biometric auth (web) | ✅ WebAuthn in browser |
| iOS kiosk app (build) | ❌ Ventura/Xcode 15 blocks iPadOS 18 |
| iOS kiosk app (use) | ✅ Run on a real iPad, point to this machine |
| RealityKit 3D interface | ❌ iOS only — not buildable on this machine |
| 70b LLM inference | ⚠️ Loads but too slow for voice |
| CUDA / GPU inference | ❌ No CUDA on macOS AMD |

---

## `.env` settings for this machine

```bash
PORT=4000
OLLAMA_URL=http://localhost:11434
OLLAMA_MODEL=llama3.2:3b        # best for real-time voice on this CPU
KOKORO_URL=http://localhost:8880
YOUSIRJUAN_API_URL=http://localhost:4000
POSTGRES_PASSWORD=sovereign
DATABASE_URL=postgresql://sovereign:sovereign@localhost:5432/yousirjuan
SESSION_SECRET=change-me-before-deployment
```
