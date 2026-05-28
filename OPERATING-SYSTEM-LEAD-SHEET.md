# You-Sir Juan™ Operating System Lead Sheet

## Purpose

This is the master implementation lead sheet for turning the repository into a deployable full cognitive operating system.

This document answers:

- what gets installed
- what order it gets installed in
- what each layer does
- how the layers connect
- how to run the stack
- how to verify the stack
- what must be configured before production

---

# System Goal

Deploy one coordinated operating system made of:

- local AI inference
- runtime API
- persistent database
- vector memory
- Redis queues
- assistant registry
- namespace permission system
- ingestion system
- evaluation system
- admin dashboard
- marketing surface
- observability system
- feature ledger
- pain journal
- ecosystem registry

---

# Supported Deployment Modes

| Mode | Purpose |
|---|---|
| Local Dev | developer machine test stack |
| Home Lab | Mac mini / MacBook / local network |
| Full Workstation | MacBook Pro M5 Max controlled install |
| Persistent Node | Mac mini always-on install |
| Edge Node | Jetson Thor install |
| VPS Node | public-facing API/admin/marketing install |
| Air-Gapped | high-security offline install |

---

# Hardware Roles

| Hardware | Role |
|---|---|
| MacBook Pro M5 Max, 128GB RAM, 4TB SSD | full workstation, coding, orchestration console, local inference |
| Mac mini M4 Max, 4TB SSD | always-on runtime, API, workers, Open WebUI, ingestion, queues |
| Jetson Thor | edge AI, robotics, vision, voice, low-latency multimodal execution |
| Flint 2 | home infrastructure gateway |
| Slate AX | secure travel networking |
| NAS / DAS / NVMe | memory, models, backups, archives |

---

# Core Install Order

## Phase 0 — Prerequisites

Install or verify:

- Git
- Node.js 20+
- npm
- Docker Desktop or Docker Engine
- Docker Compose
- Ollama
- Tailscale or WireGuard

Optional:

- Claude Code
- Continue.dev
- Aider
- Playwright CLI
- Firecrawl
- RAG Anything

---

## Phase 1 — Clone Repo

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
```

---

## Phase 2 — Configure Environment

```bash
cp .env.example .env
```

Edit `.env` before production.

---

## Phase 3 — Install Node Runtime

```bash
npm install
```

---

## Phase 4 — Start Persistent Runtime Stack

```bash
docker compose -f docker-compose.runtime.yml up -d
```

This starts:

- API runtime
- PostgreSQL
- Redis
- Qdrant

---

## Phase 5 — Start API Runtime

```bash
npm run dev:api
```

Health check:

```bash
curl http://localhost:4000/health
```

---

## Phase 6 — Provision Demo Workspace

```bash
npm run provision:demo
```

This creates:

```text
clients/smith-family/
```

with assistants, policies, memory folders, and namespace files.

---

## Phase 7 — Export Feature Ledger

```bash
npm run features:export
```

This creates a JSON-ready feature ledger for admin/API consumption.

---

## Phase 8 — Runtime Health Check

```bash
npm run health
```

---

# First-Run Verification Checklist

| Check | Command | Expected |
|---|---|---|
| API health | `curl http://localhost:4000/health` | healthy JSON |
| Feature endpoint | `curl http://localhost:4000/api/features` | feature ledger content |
| Namespace lookup | `curl http://localhost:4000/api/namespaces/smith-family` | namespace JSON |
| Docker containers | `docker ps` | postgres, redis, qdrant running |
| Demo workspace | `ls clients/smith-family` | assistants, docs, memory, policies |

---

# Operating System Layers

| Layer | Folder | Purpose |
|---|---|---|
| API Runtime | `api/` | service endpoints |
| Backend Persistence | `backend/` | database schema and backend plan |
| Runtime | `runtime/` | queue, routing, execution docs |
| Ingestion | `ingestion/` | memory ingestion workers |
| Evaluations | `evaluations/` | benchmark and trust layer |
| Features | `features/` | product feature ledger and PRDs |
| Admin | `admin/` | future command center |
| Marketing | `marketing/` | public sales engine |
| Ecosystem | `ecosystem/` | upstream tools and stack doctrine |
| Identity | `identity/` | users, workspaces, organizations |
| Observability | `observability/` | logs, metrics, audits |
| Design System | `design-system/` | visual identity and components |

---

# Production Hardening Required

Before production use, configure:

- real secrets
- secure database passwords
- HTTPS reverse proxy
- SSH key-only access
- rate limiting
- authentication
- RBAC
- backup policies
- encrypted storage
- audit retention
- namespace enforcement
- cloud-routing policies

---

# North Star

The operating system is complete when a user can run one command and receive:

- running API
- running database
- running vector DB
- running queue system
- initialized workspace
- assistant registry
- namespace policies
- memory ingestion path
- admin dashboard
- health checks
- backup hooks
- update commands

The goal is:

> one command to launch a full cognitive operating system.

---

# Engineering rules from `ai-skills-library`

This repo vendors [`marvelousempire/ai-skills-library`](https://github.com/marvelousempire/ai-skills-library) at `vendor/ai-skills-library/`. The library is the canonical source of cross-project engineering rules. Cursor and Claude pick up the generated views automatically:

- [`.cursor/rules/parallel-surfaces-from-day-one.mdc`](.cursor/rules/parallel-surfaces-from-day-one.mdc)
- [`.cursor/rules/dev-discipline.mdc`](.cursor/rules/dev-discipline.mdc)
- [`.cursor/rules/changelog-and-versioning.mdc`](.cursor/rules/changelog-and-versioning.mdc)
- [`.cursor/rules/go-live-path.mdc`](.cursor/rules/go-live-path.mdc)
- Claude twins live at [`.claude/rules/`](.claude/rules/)

**Most relevant for You-Sir Juan:** [`parallel-surfaces-from-day-one`](vendor/ai-skills-library/rules/library/parallel-surfaces-from-day-one/body.md) — every product app starts with native iOS + user web + marketing site + admin dashboard + backend/API in parallel from day one. You-Sir Juan already follows this pattern (admin/, api/, apps/, backend/, marketing surface) — the rule codifies it for every future surface and every new app spawned out of this OS.

**Updating these rules:** edit the library, push, then in this repo:
```sh
git submodule update --remote vendor/ai-skills-library
bash vendor/ai-skills-library/scripts/sync-rules-into-repo.sh .
git add vendor/ai-skills-library .cursor/rules/ .claude/rules/
git commit
```
