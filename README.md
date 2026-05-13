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

# Yours to Train

There are voice assistants in millions of homes right now. You know the ones — you say their name and they respond. They are convenient, widely available, and deeply generic. They do not know your family. They cannot. The companies that built them have no interest in learning your customs, your culture, your language, or the names of the people who matter to you. They are designed for everyone, which means they are fully tailored to no one.

You-Sir Juan™ is built on a different premise entirely.

Your family trains it. Your family owns it. No one else touches it. The system learns your names, your preferences, your routines, your priorities — the way your household actually works. It adapts to your culture, not a statistical average of everyone else's. Every interaction makes it more yours. It carries the history of your family's relationship with it, session after session, for as long as you keep it running.

This is what has been missing: an AI that belongs to a family the way a home has always belonged to its people — private, shaped by use, loyal by design, and incapable of being reconfigured by anyone else.

---

# The Interface

You-Sir Juan™ isn't just infrastructure — it's a family-grade operating layer that every member of your family office interacts with directly. The hardware is a large-format touchscreen — iPad Pro-class, wall-mounted or countertop — that any family member can walk up to at any moment.

## Walk-Up Kiosk

No phone. No password. No friction. The interface runs on a dedicated 21-inch touchscreen deployed in the family office. Members approach it the way they approach a concierge — it is always on, always ready, always theirs.

## Frictionless Biometric Authentication

The moment a family member steps in front of the screen, facial recognition fires. The system knows who they are before they touch anything. A fingerprint confirmation serves as silent second-factor authentication — a single touch, no typing, no passwords ever transmitted or stored outside the device. The entire authentication stack runs on-device using native iOS biometrics. Credentials never leave the hardware.

## Your World, Your Lens

Once authenticated, the interface doesn't open a generic dashboard — it becomes that person's world. Every family member has their own UI paradigm: a distinct color palette, layout, information hierarchy, and vocabulary tailored to how they think and what they need. The CFO sees the same underlying data as the principal — but the form is entirely different. Labels, language, and visual mood shift to match each person's mental model. The function is identical. The presentation is personal.

## Your Personal Agent

Every member is paired with a persistent AI agent — a persona they shape from the moment they onboard. Think of it as a private butler: always present, always learning, never forgetting. The agent has a voice the member selects at setup, hosted locally on the platform. It acts as the intelligent intermediary between the member and every system on the platform — querying databases, retrieving documents, executing tasks, surfacing information — and returning results in the member's chosen voice and style. The relationship accumulates over time. Context never resets.

## Voice-First Conversation

The primary mode of interaction is speech-to-speech. The member speaks; the agent listens, processes, and responds aloud in its chosen voice. The experience is conversational — not a command interface, not a search bar, but a dialogue with an AI that knows you. A text-input fallback is available for quiet environments or precision tasks. Either way, the agent is task-oriented, memory-persistent, and always in conversation.

## Onboarding

When a new member is provisioned:

1. Their profile is pre-seeded from family office records
2. They select a voice for their personal agent from locally-hosted TTS options
3. The interface adapts its visual paradigm to their preferences
4. From the first session forward, the relationship begins — and memory accumulates

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
