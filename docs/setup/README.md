# Operator Setup — Complete System Reference (Public-Safe)

**Status:** living document · **Last updated:** 2026-06-15 (expanded — voice, M5 edge, machine comms)  
**Audience:** operators, family members, and every agent (Nephew, Cursor, Claude Code, Grok, Perplexity)  
**Privacy rule:** this tree is safe for GitHub. It contains **no LAN addresses, WireGuard IPs, port numbers, domain names, credentials, or operator PII**. For live wiring (ports, peers, keys), use the private runbooks in `ledger/` and the mirrored copies under `marvelousempire/nephew/docs/infrastructure/`.

This folder is the **single front door** for understanding how the Family Office hardware, You-Sir Juan platform, and Nephew orchestration fit together.

---

## What this documents

| Chapter | File | Covers |
|---|---|---|
| 1 | [01-hardware.md](./01-hardware.md) | Every machine, its role, specs, and workload split |
| 2 | [02-network-security.md](./02-network-security.md) | Family Office Sandwich, mesh, VLANs, bind model, doors |
| 3 | [03-software-services.md](./03-software-services.md) | Containers, inference, RAG, voice, git forge, edge |
| 4 | [04-repo-ecosystem.md](./04-repo-ecosystem.md) | nephew, yousirjuan, ai-skills-library, clinic, siblings |
| 5 | [05-nephew-orchestration.md](./05-nephew-orchestration.md) | CLOAK, five layers, MCP, Pockit, cassettes, players |
| 6 | [06-retrieval-and-memory.md](./06-retrieval-and-memory.md) | Brain A/B, Qdrant, embeddings, sovereign vault |
| 7 | [07-git-and-deploy.md](./07-git-and-deploy.md) | Gitea forge, dual-push, SSH git, ship discipline |
| 8 | [08-daily-operator-workflows.md](./08-daily-operator-workflows.md) | Make targets, boot order, agent ritual, verification |
| 9 | [09-talking-to-your-machines.md](./09-talking-to-your-machines.md) | SSH, doors, tower-api, Cursor/MCP, Visual vs Jarvis, Apple hands-on |
| 10 | [10-m5-max-sovereign-edge.md](./10-m5-max-sovereign-edge.md) | M5 Nephew Max — edge daemon, hybrid routing, Obsidian, failover |
| 11 | [11-voice-parakeet-premium-stack.md](./11-voice-parakeet-premium-stack.md) | Kokoro demoted → Holler premium, Parakeet, F5 clone, routing tiers |
| 12 | [12-pockit-non-vanilla-surfaces.md](./12-pockit-non-vanilla-surfaces.md) | Suite bar, Comet motion, cassettes, Jarvis hub — non-vanilla UI synthesis |

---

## One-paragraph summary

The operator runs a **sovereign Family Office stack** on owned hardware: a **DGX Spark** is Nephew's body (inference, RAG, containers, git forge compute), a **UGREEN NAS** holds durable git objects and backups, a **VPS** is the gated public edge and Clinic, and **Mac fleet** nodes orchestrate development and the Pockit player shell. Everything internal binds to **loopback + WireGuard only** — never the open LAN. **Nephew** (orchestrator repo) sits on top of **You-Sir Juan** (infrastructure repo) and consumes **ai-skills-library** (shared skills). Family surfaces boot through **Pockit** and **cassettes** — plug-in apps reached by **door names**, not raw ports.

---

## How this relates to other docs

| Need | Where |
|---|---|
| **This setup (public, no secrets)** | `docs/setup/` ← you are here |
| Hardware deep-dive (product specs) | `hardware/`, `docs/hardware-topology.md` |
| Strategic architecture / PRD | `PRD.md`, `docs/architecture.md` |
| Repo boundaries (YSJ vs Nephew) | `REPOS-CONTRACT.md` |
| Tool & upstream registry | `ecosystem/ai-skills-and-repos-registry.md` |
| Ledger runbooks (may contain live wiring) | `ledger/LEDGER-*` |
| Nephew product vocabulary | `marvelousempire/nephew` → `docs/product-stack-glossary.md` |
| Sovereign operating principle | `marvelousempire/nephew` → `docs/sovereign.md` |
| Live fleet ground truth (operator-only) | `marvelousempire/nephew` → `docs/infrastructure/dgx-rag-and-fleet-state.md` |

**Do not duplicate secrets here.** When a runbook needs a port, IP, or key, it stays in `ledger/` or the private nephew infra mirror — not in this tree.

---

## Visual system map

```text
                    ┌─────────────────────────────────────┐
                    │   Public edge (TLS, auth gate)      │
                    │   VPS — Clinic, family apex         │
                    └──────────────────┬──────────────────┘
                                       │ WireGuard mesh
         ┌─────────────────────────────┼─────────────────────────────┐
         │                             │                             │
  ┌──────▼──────┐              ┌───────▼───────┐            ┌───────▼───────┐
  │ Mac fleet   │              │ DGX Spark     │            │ NAS           │
  │ orchestrate │◄─── WG ─────►│ Nephew body   │◄── 10GbE ─►│ git objects   │
  │ Pockit dev  │              │ LLM RAG voice │            │ backups media │
  │ Cursor/CLI  │              │ Docker stacks │            │ Historia vault│
  └─────────────┘              └───────────────┘            └───────────────┘
         │                             │
         └────────── home router ──────┘
                    VLAN segmentation
                    (Trusted / IoT / Guest)
```

---

## Agent read order

1. This README + chapters 1–5 (minimum before touching infra or cassettes).
2. Chapters 9–12 before voice, M5 edge, or Pockit surface work.
2. `marvelousempire/nephew` → `docs/product-stack-glossary.md` (Pockit, cassette, door vocabulary).
3. `marvelousempire/nephew` → `AGENTS.md` (session hooks, SOP pointers).
4. `REPOS-CONTRACT.md` (what lives in which repo).
5. Private runbooks only when executing live changes.

---

## Maintenance

When hardware, services, or repo boundaries change:

1. Update the relevant chapter in `docs/setup/`.
2. Bump `docs/CHANGELOG.md` with an Eastern timestamp.
3. If the change is substantive, add a row to `plans/README.md` or a new `plans/NNNN-*.md`.
4. Keep private wiring in `ledger/` — do not paste ports or IPs into this tree.
