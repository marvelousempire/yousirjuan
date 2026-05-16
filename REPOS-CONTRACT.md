# You-Sir Juan × Nephew Relationship Contract

**This document defines the exact roles, responsibilities, and boundaries between the You-Sir Juan and Nephew repositories.**

**Contract Version:** `1.0.0`  
**Contract Hash:** `YSJ-NEPHEW-CONTRACT-v1.0.0`  
**CI Enforcement:** ✅ Active (see `.github/workflows/contract-enforcement-*.yml`)

---

## Core Identity

### You-Sir Juan (`yousirjuan`)
**Role:** Private AI Infrastructure Platform  
**Purpose:** Hardware, servers, network topology, deployment runbooks, system tech stack  
**Tagline:** *"Your AI lives on your hardware."*

### Nephew (`nephew`)
**Role:** Orchestrator Agent by Avery Goodman  
**Purpose:** Multi-agent orchestration, personas, skills, frameworks, meta-library, family member experience  
**Tagline:** *"Multi-agent orchestration for Claude Code: swarms, a compounding Meta Library, persistent memory, cross-machine federation, and cryptographically-signed witness manifest."*

---

## What Lives Where

### ✅ You-Sir Juan Owns (Hardware + Infrastructure)

| Category | Contents |
|---|---|
| **AI Machines** | MacBook Pro M5 Max (Node A), Mac mini M4 Pro (Node B), Jetson Thor (Node C), DGX Spark (Node D) |
| **Network Hardware** | Flint 2 (WireGuard gateway), Slate AX (travel router) |
| **Network Topology** | WireGuard tunnels, device-to-device routing, mesh topology diagrams |
| **Server Configs** | `vps/` — nginx, fail2ban, iptables, systemd overrides, Ollama configs |
| **Runtime Stack** | Redis, PostgreSQL, Docker, Qdrant, Node.js/Express, Next.js |
| **Local Inference** | Ollama, vLLM, Open WebUI, OpenClaw configurations |
| **Deployment** | `tools/` — init, backup, restore, health check scripts; installer flags |
| **Repo Structure** | `broker/`, `ecosystem/`, `features/`, `ingestion/`, `media-intelligence/`, `identity/`, `assistants/`, `runtime/`, `pain-journal/` |
| **Community Integrations** | Vendored submodules: `claude-mem`, `marketingskills`, `ruflo`, `ai-skills-library` |

### ✅ Nephew Owns (Orchestration + Experience)

| Category | Contents |
|---|---|
| **Orchestration Engine** | Loop daemon, HTTP server (port 7337), MCP integration, fleet management |
| **Meta Library** | `docs/meta-library/` — compounding brain, session learnings, witnessed entries |
| **Personas/Agents** | Sterling (Avery), Blake (Robert), Cipher (NIVRAM), Sovereign (Yousir Juan) — Associate Agent definitions |
| **Interface Experience** | Walk-up kiosk flow, biometric auth, voice-first conversation, family member onboarding |
| **Frameworks** | `frameworks/` — Cinematic Broadcast Arena, future app-building templates |
| **Skills** | `skills/nephew-core/`, `skills/nephew-federation/` — Nephew's orchestration capabilities |
| **Skills Integration** | Bridge to `ai-skills-library` — consuming engineering, infra, marketing, mobile skills |
| **Memory System** | Persistent context across sessions, cross-machine federation, witness manifest |
| **Autonomous Loop** | Background tick, trigger evaluation, learning pass, lesson promotion |

### ✅ ai-skills-library Owns (Shared Catalog)

| Category | Contents |
|---|---|
| **Reusable Skills** | `skills/engineering/`, `skills/infra/`, `skills/marketing/`, `skills/mobile/`, `skills/visual/`, etc. |
| **Skill Templates** | `skills/templates/` — after-action, claude-md, hardware-doc, marketing-feature |
| **Bridges** | Integration with Nephew, Claude Code, Cursor |

---

## Clear Boundaries (What NEVER Crosses)

### ❌ You-Sir Juan DOES NOT Contain
- **No persona definitions** (Sterling, Blake, Cipher, Sovereign)
- **No Associate Agent tables** or member-agent pairings
- **No interface UX** (walk-up kiosk, biometric auth, voice-first conversation)
- **No family member onboarding** flows
- **No meta-library** or compounding brain content
- **No orchestration loop** code (tick, HTTP server, MCP)
- **No skills** (except vendored submodules as dependencies)

### ❌ Nephew DOES NOT Contain
- **No hardware specs** (MacBook Pro M5, Mac mini M4, Jetson Thor, DGX Spark)
- **No network hardware** (Flint 2, Slate AX)
- **No WireGuard configs** or topology diagrams
- **No server configs** (nginx, fail2ban, iptables, systemd)
- **No deployment scripts** (`tools/init-client-assistant.sh`, backup/restore)
- **No runtime stack** installation (Redis, PostgreSQL, Docker, Ollama servers)

---

## How They Work Together

### Data Flow

```
User (Family Member)
    ↓
Nephew (Orchestration Layer)
    ├─> Queries databases (PostgreSQL on Mac mini)
    ├─> Retrieves documents (Qdrant vector DB on Mac mini)
    ├─> Executes tasks (OpenClaw agents on Mac mini)
    ├─> Local inference (Ollama on Mac mini / DGX Spark)
    └─> Returns results via Associate Agent (Sterling/Blake/Cipher/Sovereign)
         ↓
    You-Sir Juan Infrastructure (Hardware + Runtime)
```

### Dependency Relationship

- **Nephew depends on You-Sir Juan** for:
  - Physical hardware (Mac mini, DGX Spark, Jetson Thor)
  - Network connectivity (WireGuard through Flint 2)
  - Runtime services (PostgreSQL, Redis, Ollama, Open WebUI)
  - Storage (4TB SSD on Mac mini, storage nodes)

- **You-Sir Juan does NOT depend on Nephew** for:
  - Hardware works independently
  - Infrastructure runs without orchestration
  - Can serve Open WebUI, Ollama, APIs without Nephew

### Integration Points

| Integration | How It Works |
|---|---|
| **Open WebUI ↔ Nephew** | Nephew MCP exposes `nephew` tool with green dot in Claude Code / Cursor |
| **Ollama ↔ Nephew** | Nephew calls local Ollama models on Mac mini for inference |
| **PostgreSQL ↔ Nephew** | Nephew queries family office data, persistent memory stored in PostgreSQL |
| **Qdrant ↔ Nephew** | Nephew retrieves documents via Qdrant vector search (RAG) |
| **ai-skills-library ↔ Nephew** | Nephew consumes skills from vendored `vendor/ai-skills-library` submodules |
| **Frameworks ↔ Nephew** | Nephew's `frameworks/` (e.g., Cinematic Broadcast Arena) are reusable templates for building apps |

---

## Single Source of Truth

| Repo | Source of Truth For |
|---|---|
| **yousirjuan** | Hardware inventory, network topology, server configs, deployment runbooks, tech stack |
| **nephew** | Orchestration logic, meta-library, personas, skills, frameworks, autonomous loop |
| **ai-skills-library** | Reusable skill catalog, skill templates, cross-repo skill standards |

---

## Versioning & Sync

### Contract Versioning

| Version | Date | Changes | CI Hash |
|---|---|---|---|
| 1.0.0 | May 16, 2026 | Initial contract — You-Sir Juan = infrastructure, Nephew = orchestration | `YSJ-NEPHEW-CONTRACT-v1.0.0` |

### You-Sir Juan releases
- Triggered by: Hardware changes, infrastructure updates, new server configs
- Version format: `v{hardware-tier}-{date}` (e.g., `vM4-pro-2026-05`)  
- Changelog: `CHANGELOG.md` in root

### Nephew releases
- Triggered by: Orchestration logic changes, new skills, meta-library updates
- Version format: `v{major}.{minor}.{patch}` (semver)  
- Changelog: `CHANGELOG.md` in root

### Cross-repo sync
- When You-Sir Juan infrastructure changes: Update Nephew's `docs/infrastructure/you-sir-juan-spec.md`
- When Nephew adds new skills: Update You-Sir Juan's `vendor/ai-skills-library` submodule reference
- Both repos sync via: Git submodules, shared `ai-skills-library`

---

## CI Enforcement

### Automated Checks

| Check | Repo | Workflow | What It Blocks |
|---|---|---|---|
| **No Persona Content** | You-Sir Juan | `contract-enforcement-no-persona.yml` | PRs with Sterling/Blake/Cipher/Sovereign |
| **No Interface UX** | You-Sir Juan | `contract-enforcement-no-persona.yml` | PRs with kiosk/biometric/voice-first |
| **No Meta-Library** | You-Sir Juan | `contract-enforcement-no-persona.yml` | PRs with compounding brain content |
| **No Hardware Specs** | Nephew | `contract-enforcement-no-hardware.yml` | PRs with MacBook Pro/DGX Spark specs |
| **No Network Hardware** | Nephew | `contract-enforcement-no-hardware.yml` | PRs with Flint 2/Slate AX |
| **No WireGuard Configs** | Nephew | `contract-enforcement-no-hardware.yml` | PRs with WireGuard topology |
| **Contract Sync** | Both | `contract-sync-check.yml` | Missing/invalid REPOS-CONTRACT.md |

### CI Failure Messages

If CI fails, you'll see:
- `❌ FAIL: Found persona definitions in You-Sir Juan` → Move to Nephew
- `❌ FAIL: Found hardware specs in Nephew` → Move to You-Sir Juan
- `❌ FAIL: Contract missing section` → Update REPOS-CONTRACT.md

### Bypassing CI

**Do not bypass.** Contract violations break system architecture. If you need an exception:
1. Open a discussion issue
2. Get approval from Avery Goodman
3. Update contract version before merging

---

## Onboarding a New Developer

### For Infrastructure Work (You-Sir Juan)
1. `git clone https://github.com/marvelousempire/yousirjuan`
2. Read `README.md` → Hardware specs, WireGuard topology, tech stack
3. Read `PRD.md` → Problem statement, strategic pillars
4. Read `REPOS-CONTRACT.md` → Repo boundaries
5. Run `bash tools/init-client-assistant.sh` to deploy infrastructure

### For Orchestration Work (Nephew)
1. `git clone https://github.com/marvelousempire/nephew`
2. Read `README.md` → Quick start, loop daemon, MCP integration
3. Read `REPOS-CONTRACT.md` → Repo boundaries
4. Read `docs/ARCHITECTURE.md` → Orchestration flow, meta-library
5. Run `npm run up` to start autonomous loop
6. Read `skills/cinematic-broadcast-arena.md` for app-building templates

### For Skills Work (ai-skills-library)
1. `git clone https://github.com/marvelousempire/ai-skills-library`
2. Read `SKILL-INDEX.md` → Available skills by domain
3. Read `STRUCTURE.md` → How to write a skill
4. Contribute to `skills/engineering/`, `skills/mobile/`, etc.

---

## Enforcement Checklist

Before merging a PR, verify:

### You-Sir Juan PRs
- [ ] No persona/Associate Agent content
- [ ] No interface UX (kiosk, biometric, voice-first)
- [ ] No orchestration loop code
- [ ] Only hardware, network, server configs, deployment scripts
- [ ] CI passes `contract-enforcement-no-persona.yml`

### Nephew PRs
- [ ] No hardware specs (MacBook Pro, Mac mini, DGX Spark, Jetson Thor)
- [ ] No network hardware (Flint 2, Slate AX)
- [ ] No WireGuard configs or topology diagrams
- [ ] No server deployment scripts (nginx, fail2ban, iptables)
- [ ] CI passes `contract-enforcement-no-hardware.yml`

---

## Last Updated

**Date:** May 16, 2026  
**Owner:** Avery Goodman  
**Version:** 1.0.0  
**Contract Hash:** `YSJ-NEPHEW-CONTRACT-v1.0.0`  

**Version History:**
| Version | Date | Changes |
|---|---|---|
| 1.0.0 | May 16, 2026 | Initial contract — You-Sir Juan = infrastructure, Nephew = orchestration |

This contract is **enforced by CI** — see `.github/workflows/contract-enforcement-*.yml` for automated checks. Any PR violating the contract will fail CI.  

If you're unsure where something belongs, ask: *"Is this hardware/infrastructure or orchestration/experience?"*
