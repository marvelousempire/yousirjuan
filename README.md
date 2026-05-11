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
