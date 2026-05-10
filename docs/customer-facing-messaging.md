# Customer-facing messaging (aligned with yousirjuan.ai)

This document is the **in-repo source of truth** for copy and claims that appear on the public marketing site ([yousirjuan.ai](https://yousirjuan.ai)), implemented in [`marvelousempire/yousirjuan-ai`](https://github.com/marvelousempire/yousirjuan-ai). When you change positioning, **update this file and the Next.js site together** so installers, docs, and the website stay consistent.

---

## Positioning

| Layer | Message |
|-------|--------|
| **Hero** | **Your AI lives on your hardware.** |
| **Subtitle** | Self-hosted private AI for individuals, families, and family offices. Your conversations, your models, your infrastructure — nothing leaves your machines (unless you explicitly opt into a cloud API). |
| **Trainable-memory story** (this repo’s long-term vision) | “Teach your own AI support staff” — persistent relationship memory across households, family offices, PMAs, and portfolio businesses. See [README.md](../README.md) and [vision-trainable-ai-assistants-platform.md](vision-trainable-ai-assistants-platform.md). |

---

## Feature grid (site § features)

These bullets are what the marketing site promises the **default stack** delivers:

1. **Local LLM inference** — Ollama; models pulled and run locally (Llama, Qwen, Gemma, etc.).
2. **ChatGPT-style web UI** — Open WebUI: accounts, history, prompts, knowledge bases, OAuth-ready.
3. **Built-in RAG** — Upload PDFs/docs/URLs; local embeddings; per-user or shared collections.
4. **Encrypted device mesh** — Tailscale (WireGuard) between laptops, phones, tablets, servers.
5. **Public HTTPS endpoint** (optional profile) — nginx + Let’s Encrypt; family/staff use a real URL.
6. **Defense in depth** — fail2ban, iptables INPUT + DOCKER-USER lockdown, OOM-safe swap, app-level auth.

Principles repeated on-site: **no telemetry**, **no third-party-required**, **no vendor lock-in** (swap components; export data).

---

## How it works (three steps)

1. **Install** — Signed macOS `.pkg` or one-line script on Linux; wizard detects hardware and recommends a profile (~10–15 minutes).
2. **Use** — Open WebUI (e.g. `localhost:3000`); first user is admin; pick a model; chat; upload docs; build assistants.
3. **Share** — Add family or staff; optional public HTTPS + Google sign-in; operator stays in control.

---

## Privacy: “What stays where” (honest table)

| Data | Where it lives | Who sees it |
|------|----------------|-------------|
| Conversations + uploads | Your hardware (Docker volume) | Only you / your users |
| Local model inference | Your CPU/GPU | Stays on your machine |
| Mesh between devices | Tailscale (WireGuard) | Tailscale Inc. cannot decrypt payload |
| HTTPS cert (if public) | Let’s Encrypt | They see the domain exists, not your data |
| Model downloads from Ollama | Your hardware after pull | CDN sees the pull, not inference |
| Cloud API (if opt-in) | Sent to that provider | Provider sees that traffic only |

---

## System requirements (download page)

| Tier | Spec | Scope |
|------|------|--------|
| **Minimum (chat only)** | 4 GB RAM · ~15 GB disk · any CPU | Ollama + Open WebUI |
| **Recommended (full stack)** | 16 GB RAM · ~30 GB disk · Apple Silicon or NVIDIA GPU | Adds OpenClaw / agent layer |
| **Family office (public)** | Linux VPS · ~4 GB RAM · ~20 GB disk · domain | nginx + TLS + lockdown |

**macOS Intel note (marketing):** OpenClaw may be slow or unstable CPU-only; “chat only” profile recommended on older Intel Macs.

---

## Install entrypoints (keep in sync with site)

- **From source (this repo):**  
  `git clone https://github.com/marvelousempire/yousirjuan.git && cd yousirjuan && bash bootstrap.sh`
- **One-liner (when live):**  
  `curl -fsSL https://get.yousirjuan.ai | sh` — must match what the download page documents.
- **Signed installers:** GitHub Releases on **`yousirjuan-ai`** (not this repo). See below.

---

## Releases & signed installers

- **Source + scripts:** this repository (`yousirjuan`).
- **Public downloads + checksums:** [`marvelousempire/yousirjuan-ai` Releases](https://github.com/marvelousempire/yousirjuan-ai/releases).
- **Build pipeline:** [.github/workflows/release-installer.yml](../.github/workflows/release-installer.yml) — tag `v*.*.*` (or `workflow_dispatch`) builds and signs macOS `.pkg`, uploads to the **public** `yousirjuan-ai` repo so the website’s Download buttons work without exposing optional private forks.

---

## Calls to action (site)

- Primary: **Download for [platform]** (detected client-side).
- Secondary: **Other platforms · view all options** → `/download`.
- Closing: **Stop sending your conversations to OpenAI** — same hardware promise in 10–15 minutes.

---

## Related internal docs

- [PRD.md](../PRD.md) — requirements and acceptance criteria.
- [HANDOFF.md](../HANDOFF.md) — production topology and operator notes.
- [architecture.md](architecture.md) — technical stack diagram.
