# CLAUDE.md — You-Sir Juan™

This file is read by Claude Code at the start of every session. It tells the agent what this repo is, where to find the skills library, and how to route work to the right tools.

---

## What this repo is

**You-Sir Juan™** is a sovereign private AI infrastructure platform for family offices and households. It is:

- a backend runtime (Node.js/Express, Postgres, Redis, Qdrant, Ollama)
- a native iOS/iPadOS app (SwiftUI + RealityKit 4 — kiosk interface)
- a web client (Next.js 15 + Tailwind 4 + Framer Motion)
- a family-trainable Associate Agent system (4 personas, voice-first, persistent memory)
- a hardware-aware deployment system (Mac mini → DGX Spark spectrum)

**Source of truth:** `marvelousempire/yousirjuan` (this repo).
**Skills library:** `vendor/ai-skills-library/` (git submodule — do not copy, reference in place).

---

## Skills library

The operator's curated AI skills catalog lives at:

```
vendor/ai-skills-library/
```

It is a **git submodule** pinned to `marvelousempire/ai-skills-library` on `main`. Never copy files out of it — consume them by reference.

**You-Sir Juan platform skills** (agent-managed, six skills): `vendor/ai-skills-library/skills/yousirjuan/<skill-id>/` — **not** `skills/project/yousirjuan/`. Install into Cursor: `cd vendor/ai-skills-library && ./scripts/install-repo-skills-to-cursor-project.sh "$(cd ../.. && pwd)"`. Rule: `vendor/ai-skills-library/rules/library/yousirjuan-skills-pack-path/body.md`.

### Where to start

| What you need | Read this first |
|---|---|
| Which tool to use for any task in this repo | [`vendor/ai-skills-library/docs/yousirjuan-platform-skills-master.md`](vendor/ai-skills-library/docs/yousirjuan-platform-skills-master.md) |
| Full skill index (68 skills, all categories) | [`vendor/ai-skills-library/SKILL-INDEX.md`](vendor/ai-skills-library/SKILL-INDEX.md) |
| Agent routing rules | [`vendor/ai-skills-library/AGENTS.md`](vendor/ai-skills-library/AGENTS.md) |
| Rules for code style + discipline | [`vendor/ai-skills-library/rules/`](vendor/ai-skills-library/rules/) |
| How to add or update a skill | [`vendor/ai-skills-library/docs/add-skill.md`](vendor/ai-skills-library/docs/add-skill.md) |

### Quick routing (from the skills master)

| Task | Use |
|---|---|
| Build or edit code | Coding Intelligence (Claude Code, Aider, Continue.dev) |
| Run local models | Ollama (Mac mini default) or DGX Spark (set `OLLAMA_URL`) |
| Ingest documents / memory | RAG Anything → Qdrant → SentenceTransformers |
| Browser automation / testing | Playwright (`apps/yousirjuan-web/e2e/`) |
| UI / frontend polish | UI/UX Pro Max + Framer Motion + Tailwind + shadcn/ui |
| Video / images / demos | Media Intelligence (ComfyUI, Flux, Higgsfield) |
| Voice / speech | Whisper (STT) + Kokoro (TTS, in `docker-compose.yml`) |
| Deployment / infra | Docker Compose + WireGuard + nginx |
| Git / governance | Git + GitHub → GitLab CE (planned) |
| Hardware placement | `docs/hardware-topology.md` + skills master §12 |

---

## Key repo files

| File | Purpose |
|---|---|
| `README.md` | Product vision — "Yours to Train" + "The Interface" + full stack |
| `PRD.md` | Platform-level product requirements |
| `OPERATING-SYSTEM-LEAD-SHEET.md` | Master install order, deploy modes, health checks |
| `plans/family-interface-vision.md` | Full build roadmap (software + hardware + service) |
| `docs/hardware-topology.md` | Node roles and workload placement |
| `docs/hardware/apple-device-stack.md` | Apple hardware inventory + pricing |
| `hardware/dgx-spark-frontier-node.md` | DGX Spark sovereign compute role |
| `docs/cinematic-3d-ios-prd.md` | RealityMotion iOS design system PRD (SwiftUI + RealityKit 4) |
| `apps/README.md` | How to run backend + iOS + web in 3 terminals |
| `.env.example` | All environment variables documented |
| `docker-compose.yml` | Services: Ollama, Postgres, Redis, Qdrant, Kokoro, nginx |
| `docker-compose.runtime.yml` | Runtime stack: API + Postgres + Redis + Qdrant |

---

## Associate Agents — the four members

| userId | Name | Agent name | Palette | UI paradigm |
|---|---|---|---|---|
| `u_avery` | Avery Goodman | Sterling | Obsidian `#7C5CFF` | executive-grid / serif-strong |
| `u_bobby` | Robert Bobby | Blake | Copper `#FF6B35` | soft-stack / humanist-rounded |
| `u_nivram` | NIVRAM | Cipher | Matrix `#00FF88` | developer-dense / monospace-sharp |
| `u_yousirjuan` | Yousir Juan | Sovereign | Sovereign `#FFD700` | command-center / display-bold |

Seeded in `api/src/personas.js`. Terminology rule: always say **Associate Agent** or **Associate** — never "butler" or "persona" in user-facing strings.

---

## Running the system

```bash
# 1. Backend (port 4000)
pnpm install && pnpm dev:api

# 2. Web client (port 3000)
cd apps/yousirjuan-web && pnpm install && pnpm dev

# 3. iOS — Xcode Simulator
cd apps/yousirjuan-ios && xcodegen generate && open YouSirJuan.xcodeproj

# 4. Full Docker stack (Ollama + Postgres + Redis + Qdrant + Kokoro + nginx)
docker compose up -d

# 5. Tests
pnpm test                                    # Jest — 18/18 backend tests
cd apps/yousirjuan-web && pnpm test:e2e      # Playwright e2e
```

---

## Ledger — codified runbooks & playbooks

See [`ledger/`](ledger/) for replayable task knowledge. Each entry is one task captured as a ticket + runbook(s) + playbook(s). **Before invoking work that already has a ledger entry, replay the playbook directly** — no AI in the loop.

Adding to the ledger is the default closing ritual for any non-trivial task in this repo; see [`.claude/rules/ledger-discipline.md`](.claude/rules/ledger-discipline.md) for the rule and [`ledger/README.md`](ledger/README.md) for the index, schema, and format-choice guide.

### Remote development on the VPS

When you (or the operator) need to open a remote VS Code window on the production VPS (`vps-godaddy` — Ubuntu 24.04 on GoDaddy, SSH on **port 2222**, not 22), the canonical guide is [`ledger/LEDGER-0003-vscode-remote-vps/`](ledger/LEDGER-0003-vscode-remote-vps/). Four runbooks (extension install, SSH alias, connect, troubleshoot) plus an idempotent install playbook. The status check is one line:

```bash
bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh status
```

If the operator reports "refused" or "permission denied," do not iterate auth attempts (fail2ban). Read [`runbooks/04-troubleshoot-refused-connections.md`](ledger/LEDGER-0003-vscode-remote-vps/runbooks/04-troubleshoot-refused-connections.md) first — six patterns; match symptoms to one of them before changing anything.

## Tool-neutral entrypoint for new agents

When an agent that isn't Claude Code lands in this repo (Cursor, Aider, Continue, a future tool), the orientation file is [`AGENTS.md`](AGENTS.md) at repo root. It mirrors what this CLAUDE.md describes but without Claude-specific hooks. Cursor-readable rules live at [`.cursor/rules/`](.cursor/rules/).

---

## Hardware targets

| Tier | Minimum hardware |
|---|---|
| Floor — entry product | Mac mini M4 Pro 48GB + iPad Pro (any M-series, iPadOS 18+) + GL.iNet Flint 2 |
| Ceiling — full sovereign mesh | MacBook Pro M5 Max + Mac mini M4 Pro + DGX Spark + Jetson Thor + Flint 2/Slate AX + NAS |

Swap `OLLAMA_URL` in `.env` to route inference between Mac mini (floor) and DGX Spark (ceiling).

---

## Submodule hygiene

```bash
# Initialize after a fresh clone
git submodule update --init --recursive

# Pull latest from ai-skills-library main
cd vendor/ai-skills-library && git checkout main && git pull
cd ../.. && git add vendor/ai-skills-library
git commit -m "chore(vendor): bump ai-skills-library to latest main"

# Check current submodule commit
git submodule status
```

---

## Commit convention

| Prefix | When to use |
|---|---|
| `feat:` | new feature |
| `fix:` | bug fix |
| `chore:` | maintenance, deps, vendor bumps |
| `docs:` | documentation only |
| `refactor:` | structure change, no behavior change |
| `test:` | tests only |
