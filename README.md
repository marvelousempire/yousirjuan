# You-Sir Juan™

# Private AI Infrastructure Platform

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
| Node B | Mac mini with M4 Pro chip | 14-core CPU, 20-core GPU, 16-core Neural Engine, 48GB unified memory, 1TB SSD storage, 10 Gigabit Ethernet, Thunderbolt 5 connectivity | Persistent orchestration server for Open WebUI, Ollama, embeddings, vector databases, APIs, queues, local AI services, and infrastructure routing |
| Node C | NVIDIA Jetson Thor | Edge AI acceleration node | Robotics, voice systems, vision pipelines, local automation, edge inference, and distributed experimentation |
| Node D | NVIDIA DGX Spark | Compact Grace Blackwell AI workstation | Frontier inference, CUDA-native AI workloads, TensorRT acceleration, fine-tuning, and large-model serving |

---

# Planned Community Integrations (Phase 2.5+)

You-Sir Juan will fork these upstream projects under `marvelousempire/<name>` with **upstream-sync GitHub Actions** (daily auto-pull from upstream `main`), a **lightweight rebrand** layer, and **legally-required attribution preserved** (LICENSE + copyright headers untouched, plus `NOTICE` and `CREDITS.md` in each fork). Each becomes an opt-in install profile flag in `bootstrap.sh`.

| Project | Upstream | License | Stars | What it adds | Install flag |
|---|---|---|---|---|---|
| **claude-mem** | [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | Apache 2.0 | 73.7k | Persistent memory + context for Claude Code across sessions. Useful for operators who maintain the platform with Claude Code — saves you from re-explaining the project every session. SQLite + Chroma vector search, 5 lifecycle hooks, HTTP API on port 37777. | `INSTALL_CLAUDE_MEM=1` |
| **marketingskills** | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | MIT | 27.3k | Pre-built marketing-domain skills (copywriting, SEO, conversion optimization, analytics, growth engineering). Bundled into Open WebUI as Knowledge + shared Models so any user can ask "draft a Q4 marketing brief" and get expert-quality output. | `INSTALL_MARKETING_SKILLS=1` |
| **ruflo** | [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | MIT | 46.7k | Multi-agent orchestration via MCP — coordinates 100+ specialized agents with shared context, persistent memory across sessions, and secure federation. Possible alternative or complement to OpenClaw for advanced agent workflows. | `INSTALL_RUFLO=1` |

**Fork-and-maintain pattern (per upstream):**

```bash
# 1. Fork via gh CLI
gh repo fork <upstream-owner>/<repo> --org marvelousempire --clone

# 2. Add upstream remote + create our branch
git remote add upstream https://github.com/<upstream-owner>/<repo>.git
git checkout -b marvelous-main

# 3. Daily auto-sync via .github/workflows/sync-upstream.yml
#    Pulls upstream/main into our main; rebases marvelous-main on top.
```

**Status:** ❌ not yet forked. Tracked in [PRD.md §13](PRD.md) as Phase 2.5 work. Currently sequenced after the marketing website + signed `.pkg` installer pipeline (which are already shipped).
