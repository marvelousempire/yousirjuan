# You-Sir Juan™

# Private AI Infrastructure Platform

**You-Sir Juan™ is a private, self-hosted AI infrastructure platform for individuals, families, and small organizations — especially family offices — that need enterprise-grade AI without sending their data to anyone else.** *"Your AI lives on your hardware."*

Private AI infrastructure focused on:

- local inference
- intelligent orchestration
- multimodal retrieval
- private memory systems
- coding workflows
- autonomous tooling
- organizational continuity
- AI-assisted operations

---

# The Problem It Solves

The market today forces a painful choice:

| Path | What you get | What you give up |
|---|---|---|
| **ChatGPT / Claude / Gemini** | Best-in-class quality, zero setup | Your conversations, uploads, and behavior patterns become training data. Data exfiltration risk for legal, financial, health, and family content. |
| **Roll-your-own from scratch** | Total privacy, total control | Weeks of engineering work, brittle setup, no clear path, no security hardening |
| **Enterprise self-hosted** | Privacy + quality | $50K–$1M+ annual contracts, vendor lock-in, still a vendor in the loop |

**The gap:** a self-contained, open-source, drop-in private AI stack that a family office, small-business owner, or technically-curious individual can deploy on their own hardware in an afternoon and trust for years.

You-Sir Juan fills that gap.

---

# Executive Summary

You-Sir Juan™ is evolving into:

> a private AI infrastructure and orchestration platform.

The project combines:

- local AI infrastructure
- retrieval systems
- coding intelligence
- orchestration workflows
- memory systems
- evaluation pipelines
- autonomous tooling
- secure WireGuard networking
- operational continuity architecture

into one coordinated ecosystem.

---

# Quick Start

Any technically-comfortable user can `git clone` and stand up the full stack in **under 30 minutes**:

```bash
git clone https://github.com/marvelousempire/yousirjuan
cd yousirjuan
git submodule update --init --recursive
bash tools/init-client-assistant.sh
```

---

# Core Tech Stack

| Component | Role |
|---|---|
| **Ollama** | Local model inference |
| **Open WebUI** | Multi-user chat + RAG (document retrieval) |
| **OpenClaw** | Messaging-platform agents |
| **Tailscale** | Encrypted WireGuard mesh networking |
| **nginx + Let's Encrypt** | Public endpoint with TLS |
| **Redis** | Task queue |
| **PostgreSQL** | Primary database |
| **Qdrant / LanceDB** | Vector database for retrieval |

---

# Repo Structure

| Directory | Purpose |
|---|---|
| `broker/` | Local verb-based action broker (read-file, screenshot, open-url, type-text) |
| `ecosystem/` | Architecture maps, tool registry, upstream repo ledger |
| `features/` | PRDs and feature ledger |
| `ingestion/` | Data ingestion pipelines |
| `media-intelligence/` | Media AI pipelines |
| `identity/` | Personal AI context and identity |
| `assistants/` | Assistant registry and memory systems |
| `vps/` | Server hardening configs (nginx, fail2ban, iptables, systemd) |
| `tools/` | Shell scripts for init, backup, restore, health checks |
| `hardware/` | Hardware-specific configuration notes |
| `runtime/` | Task queue and Redis architecture |
| `pain-journal/` | Operational issue tracking |

---

# Strategic Pillars

1. **Privacy-by-default** — Zero telemetry. No phone home. Conversations and uploads never leave operator hardware unless explicitly routed to a cloud API.
2. **Reproducible** — The repo is the source of truth. Every byte of configuration is in git. Anyone with the repo + a domain can stand up an identical deployment.
3. **Hardware-honest** — The installer detects hardware and recommends realistic profiles. CPU-only boxes get a "chat only" profile that works; M-series + GPU boxes get the full stack with the agent layer.
4. **Defense in depth** — TLS at the edge, firewall on the host, app-level auth, rate limits, fail2ban, encrypted mesh between devices, swap-protected against OOM cascades.
5. **Boring stack** — Off-the-shelf battle-tested pieces (nginx, Ollama, Postgres, systemd). Minimal proprietary glue. If we go away, the stack still works.
6. **No lock-in** — Operator can swap any component. Operator can take their data and leave anytime — backup tarball is fully portable.

---

# What This Is NOT

- Not a SaaS (today). No central control plane, no shared multi-tenancy.
- Not a managed service. The operator is responsible for hardware, network, and ongoing security.
- Not an Anthropic / OpenAI substitute for every use case. Local 8B–30B models are good but not frontier. Cloud providers remain available as opt-in for non-sensitive heavy lifting.

---

---

# Infrastructure Stack

| Layer | Preferred Systems |
|---|---|
| Runtime | Node.js / Express |
| Database | PostgreSQL |
| Queue System | Redis |
| Vector Database | Qdrant |
| UI | Next.js |
| Containerization | Docker |
| Networking | WireGuard |
| Infrastructure Routers | Flint 2 / Slate AX |
| Local Inference | Ollama / vLLM |
| Coding Workflows | Continue.dev / Aider |
| Browser Automation | Playwright |
| Retrieval | Qdrant / LanceDB |
| Edge AI | NVIDIA Jetson Thor |
| Frontier Inference | NVIDIA DGX Spark |
| Governance | GitLab CE |

---

# Network Infrastructure Hardware

| Hardware | Purpose |
|---|---|
| Flint 2 | Primary WireGuard gateway, home infrastructure router, VPN hub, private AI network backbone |
| Slate AX | Portable WireGuard travel router for encrypted mobile access into home infrastructure |

---

# WireGuard Infrastructure Topology

```text
Laptop / iPad / Phone
        ↓
Slate AX Travel Router
        ↓
Encrypted WireGuard Tunnel
        ↓
Flint 2 Infrastructure Gateway
        ↓
Mac mini Runtime Server
        ↓
DGX Spark / Jetson Thor / Storage Nodes
```

---

# WireGuard Network Layer

WireGuard is the preferred secure network layer for the platform.

It provides:

- encrypted private tunnels
- direct device-to-device connectivity
- lower dependency on third-party coordination services
- strong fit for self-hosted infrastructure
- clean routing between workstation, Mac mini, DGX Spark, Jetson Thor, VPS, and storage nodes

The WireGuard layer is primarily hosted through:

- Flint 2 as the central infrastructure gateway
- Slate AX as the portable encrypted travel node

Recommended role split:

| Network Role | Hardware / Service |
|---|---|
| Home gateway | Flint 2 running WireGuard server |
| Travel tunnel | Slate AX running WireGuard client |
| Persistent runtime node | Mac mini connected through WireGuard |
| Workstation node | MacBook Pro connected through WireGuard |
| Edge node | Jetson Thor connected through WireGuard |
| Frontier node | DGX Spark connected through WireGuard |
| Public/server node | VPS connected through WireGuard |

---

# AI Machine Specs

| Node | Machine | Exact Configuration | Intended Purpose |
|---|---|---|---|
| Node A | 16-inch MacBook Pro M5 Max | 18-core CPU, 40-core GPU, 16-core Neural Engine, 128GB unified memory, 4TB SSD, nano-texture display | Main AI workstation for local inference, coding workflows, orchestration testing, and private development |
| Node B | Mac mini with M4 Pro chip | 14-core CPU, 20-core GPU, 16-core Neural Engine, 48GB unified memory, 4TB SSD storage, 10 Gigabit Ethernet, Thunderbolt 5 connectivity | Persistent orchestration server for Open WebUI, Ollama, embeddings, vector databases, APIs, queues, local AI services, and infrastructure routing |
| Node C | NVIDIA Jetson Thor | Edge AI acceleration node | Robotics, voice systems, vision pipelines, local automation, edge inference, and distributed experimentation |
| Node D | NVIDIA DGX Spark | Compact Grace Blackwell AI workstation | Frontier inference, CUDA-native AI workloads, TensorRT acceleration, fine-tuning, and large-model serving |

---

# Community Integrations — vendored under `vendor/`

These upstream projects are **forked under `marvelousempire/<name>` (private)** and **vendored as git submodules** in this repo at `vendor/<name>`. Each fork has an `upstream-sync` GitHub Action that daily pulls the latest upstream `main` into our `main`; our customizations live on a long-lived `marvelous-main` branch tracked by the submodule reference. `NOTICE` + `CREDITS.md` files in each fork preserve the legally-required attribution (LICENSE + copyright headers untouched).

| Project | Upstream | Our fork | License | Stars | Install flag (planned) |
|---|---|---|---|---|---|
| **claude-mem** | [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | [marvelousempire/claude-mem](https://github.com/marvelousempire/claude-mem) (private) → `vendor/claude-mem` | Apache 2.0 | 73.7k | `INSTALL_CLAUDE_MEM=1` |
| **marketingskills** | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | [marvelousempire/marketingskills](https://github.com/marvelousempire/marketingskills) (private) → `vendor/marketingskills` | MIT | 27.3k | `INSTALL_MARKETING_SKILLS=1` |
| **ruflo** | [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | [marvelousempire/ruflo](https://github.com/marvelousempire/ruflo) (private) → `vendor/ruflo` | MIT | 46.7k | `INSTALL_RUFLO=1` |
| **ai-skills-library** | (operator's own) | [marvelousempire/ai-skills-library](https://github.com/marvelousempire/ai-skills-library) (private) → `vendor/ai-skills-library` | proprietary | — | (curated catalog) |

**What it adds:**
- `claude-mem` — persistent memory + context for Claude Code across sessions (for operators maintaining the platform). SQLite + Chroma vector search, 5 lifecycle hooks, HTTP API on port 37777.
- `marketingskills` — pre-built marketing-domain skills (copywriting, SEO, conversion, analytics, growth engineering). Bundled into Open WebUI as Knowledge + shared Models.
- `ruflo` — multi-agent orchestration via MCP. Coordinates 100+ specialized agents with shared context, persistent memory, and secure federation. Possible alternative or complement to OpenClaw.
- `ai-skills-library` — operator's curated catalog for Cursor + Claude Code skills (already vendored before this PR).

**Working with submodules:**

```bash
# After cloning yousirjuan, hydrate the submodules:
git submodule update --init --recursive

# Pull latest from each fork's marvelous-main:
git submodule update --remote --merge

# When upstream releases a new version (auto-sync workflow already pulled into our main):
cd vendor/<name>
git checkout marvelous-main
git rebase main
git push --force-with-lease origin marvelous-main
cd ../..
git add vendor/<name>
git commit -m "chore(vendor): bump <name> to latest upstream"
```

**Status:** ✅ forked + vendored. Installer-flag wiring (`bash bootstrap.sh` flags actually configuring each integration into Open WebUI / OpenClaw / Claude Code) tracked in [PRD.md §13](PRD.md) as remaining Phase 2.5 work.
