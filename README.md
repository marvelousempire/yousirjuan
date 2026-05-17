# You-Sir Juan™

## Private AI Infrastructure Platform

**You-Sir Juan™ is a private, self-hosted AI infrastructure platform for individuals, families, small organizations, and family offices that need useful AI without handing sensitive data to a third party.** Your AI lives on your hardware.

The platform brings local inference, retrieval, private memory, orchestration, coding workflows, autonomous tools, and secure networking into one reproducible stack.

## The Problem

Most AI infrastructure choices force a tradeoff:

| Path | What You Get | What You Give Up |
|---|---|---|
| Hosted AI apps | Best-in-class quality with almost no setup | Conversations, uploads, workflows, and behavior patterns leave your environment |
| Roll your own | Total privacy and control | Weeks of engineering, brittle setup, unclear hardening, and long-term maintenance burden |
| Enterprise self-hosting | Privacy plus mature tooling | High contracts, vendor lock-in, and a vendor still sitting inside the operating model |

You-Sir Juan fills the gap: a self-contained private AI stack that a technically comfortable operator can deploy on owned hardware, inspect, back up, and keep running.

## What It Coordinates

- Local model inference
- Multimodal retrieval and vector search
- Private memory systems
- Associate Agent orchestration
- Coding and automation workflows
- Secure WireGuard networking
- Operational continuity, backups, and restore paths
- Hardware-aware deployment from Mac mini to frontier nodes

## Yousir Juan Technical Operator

Yousir Juan is the platform's master IT and AI infrastructure Associate Agent. It is the framework source for putting infrastructure together across software, hardware, networking, automation, troubleshooting, and deployment work.

At minimum, Yousir Juan operates like an engineer. It can install and configure systems, wire local AI runtimes, set up developer environments, build reverse-proxy routes, manage package managers, troubleshoot runtime failures, and scale the platform from small Mac mini deployments to Mac Studio, Mac Pro, Jetson Thor, DGX Spark, and other edge or frontier AI nodes.

Yousir Juan should be comfortable authoring:

- Ansible playbooks
- Dockerfiles, images, containers, and deployment packages
- GitHub Actions and workflow files
- Bash, Node.js, and Python automation scripts
- repo-owned micro-slices that behave like internal workflow actions
- quick spin-up kits for repeated services, stacks, and environments

For local Docker infrastructure, the preferred operating path is Colima-backed Docker with Dockyard as the container management surface. When a setup pattern repeats, Yousir Juan packages it as a reusable kit, splits it into micro-slices when useful, and stores the known-good pattern in the Cabinet/Kitchen library for future builds.

## Quick Start

Any technically comfortable user can clone the repo and stand up the stack:

```bash
git clone https://github.com/marvelousempire/yousirjuan
cd yousirjuan
git submodule update --init --recursive
bash tools/init-client-assistant.sh
```

For local development across surfaces, see `apps/README.md`.

## Core Tech Stack

| Component | Role |
|---|---|
| Ollama | Local model inference |
| Open WebUI | Multi-user chat and RAG |
| OpenClaw | Messaging-platform agents |
| WireGuard / Tailscale | Encrypted private mesh networking |
| nginx + Let's Encrypt | Public endpoint with TLS |
| Redis | Task queue and runtime coordination |
| PostgreSQL | Primary relational database |
| Qdrant / LanceDB | Vector database and retrieval layer |

## Infrastructure Stack

| Layer | Preferred Systems |
|---|---|
| Runtime | Node.js / Express |
| User and admin web | Next.js |
| Native app | SwiftUI / RealityKit |
| Database | PostgreSQL |
| Queue system | Redis |
| Vector database | Qdrant |
| Containerization | Docker / Docker Compose |
| Networking | WireGuard |
| Infrastructure routers | Flint 2 / Slate AX |
| Local inference | Ollama / vLLM |
| Coding workflows | Cursor / Claude Code / Continue.dev / Aider |
| Browser automation | Playwright |
| Edge AI | NVIDIA Jetson Thor |
| Frontier inference | NVIDIA DGX Spark |
| Governance | GitLab CE |

## Network Infrastructure Hardware

| Hardware | Purpose |
|---|---|
| Flint 2 | Primary WireGuard gateway, home infrastructure router, VPN hub, and private AI network backbone |
| Slate AX | Portable WireGuard travel router for encrypted mobile access into home infrastructure |

## WireGuard Topology

```text
Laptop / iPad / Phone
        |
Slate AX Travel Router
        |
Encrypted WireGuard Tunnel
        |
Flint 2 Infrastructure Gateway
        |
Mac mini Runtime Server
        |
DGX Spark / Jetson Thor / Storage Nodes
```

WireGuard is the preferred secure network layer because it provides encrypted private tunnels, direct device-to-device connectivity, minimal third-party dependency, and clean routing between workstation, Mac mini, DGX Spark, Jetson Thor, VPS, and storage nodes.

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

## AI Machine Specs

| Node | Machine | Exact Configuration | Intended Purpose |
|---|---|---|---|
| Node A | 16-inch MacBook Pro M5 Max | 18-core CPU, 40-core GPU, 16-core Neural Engine, 128GB unified memory, 4TB SSD, nano-texture display | Main AI workstation for local inference, coding workflows, orchestration testing, and private development |
| Node B | Mac mini with M4 Pro chip | 14-core CPU, 20-core GPU, 16-core Neural Engine, 48GB unified memory, 4TB SSD storage, 10 Gigabit Ethernet, Thunderbolt 5 connectivity | Persistent orchestration server for Open WebUI, Ollama, embeddings, vector databases, APIs, queues, local AI services, and infrastructure routing |
| Node C | NVIDIA Jetson Thor | Edge AI acceleration node | Robotics, voice systems, vision pipelines, local automation, edge inference, and distributed experimentation |
| Node D | NVIDIA DGX Spark | Compact Grace Blackwell AI workstation | Frontier inference, CUDA-native AI workloads, TensorRT acceleration, fine-tuning, and large-model serving |

## Repo Structure

| Directory | Purpose |
|---|---|
| `api/` | Backend API, Associate Agent routing, personas, and runtime services |
| `apps/` | Native iOS and web application surfaces |
| `assistants/` | Assistant registry and memory systems |
| `broker/` | Local verb-based action broker |
| `docs/` | Architecture, hardware, onboarding, and operating documentation |
| `ecosystem/` | Architecture maps, tool registry, and upstream repo ledger |
| `features/` | PRDs and feature ledgers |
| `hardware/` | Hardware-specific configuration notes |
| `identity/` | Personal AI context and identity material |
| `ingestion/` | Data ingestion pipelines |
| `media-intelligence/` | Media AI pipelines |
| `runtime/` | Queue and runtime coordination architecture |
| `tools/` | Init, backup, restore, and health-check scripts |
| `vendor/` | Vendored upstream projects and skills library submodules |
| `vps/` | Server hardening configs for nginx, fail2ban, iptables, and systemd |

## Strategic Pillars

1. **Privacy by default** - zero telemetry, no phone-home behavior, and no sensitive data leaving operator hardware unless explicitly routed to a cloud API.
2. **Reproducible infrastructure** - the repo is the source of truth, and configuration belongs in git.
3. **Hardware honesty** - the stack should detect realistic hardware profiles and recommend workloads each machine can actually run.
4. **Defense in depth** - TLS at the edge, host firewalls, app-level auth, rate limits, fail2ban, encrypted mesh networking, and swap protection against OOM cascades.
5. **Boring foundations** - battle-tested pieces such as nginx, Ollama, Postgres, Redis, Docker, and systemd carry the platform.
6. **No lock-in** - operators can swap components, export data, back up state, and leave with a portable system.

## What This Is Not

- Not a hosted SaaS control plane today. There is no central shared multi-tenant service.
- Not a managed service. The operator remains responsible for hardware, networking, updates, and security posture.
- Not a universal replacement for frontier hosted models. Local models are useful and private, while cloud models remain opt-in for non-sensitive heavy work.
- Not a single-device demo. The platform is designed around durable local infrastructure, private networking, and multi-surface access.

## Community Integrations

Community projects are forked under `marvelousempire/<name>` and vendored into this repo as git submodules at `vendor/<name>`. Forks preserve upstream licenses and attribution while allowing long-lived platform customizations.

| Project | Upstream | Our Fork | License | Install Flag |
|---|---|---|---|---|
| claude-mem | [thedotmack/claude-mem](https://github.com/thedotmack/claude-mem) | `marvelousempire/claude-mem` -> `vendor/claude-mem` | Apache 2.0 | `INSTALL_CLAUDE_MEM=1` |
| marketingskills | [coreyhaines31/marketingskills](https://github.com/coreyhaines31/marketingskills) | `marvelousempire/marketingskills` -> `vendor/marketingskills` | MIT | `INSTALL_MARKETING_SKILLS=1` |
| ruflo | [ruvnet/ruflo](https://github.com/ruvnet/ruflo) | `marvelousempire/ruflo` -> `vendor/ruflo` | MIT | `INSTALL_RUFLO=1` |
| ai-skills-library | Operator-maintained catalog | `marvelousempire/ai-skills-library` -> `vendor/ai-skills-library` | Proprietary | Curated catalog |

What they add:

- `claude-mem` provides persistent memory and context for Claude Code across operator sessions.
- `marketingskills` provides marketing-domain skills for copywriting, SEO, conversion, analytics, and growth work.
- `ruflo` provides multi-agent orchestration via MCP and can complement the platform's agent layer.
- `ai-skills-library` is the curated Cursor and Claude Code skills catalog used by this repo.

Submodule workflow:

```bash
# Hydrate submodules after cloning.
git submodule update --init --recursive

# Pull latest from tracked submodule branches.
git submodule update --remote --merge

# Update a customized fork after upstream sync.
cd vendor/<name>
git checkout marvelous-main
git rebase main
git push --force-with-lease origin marvelous-main
cd ../..
git add vendor/<name>
git commit -m "chore(vendor): bump <name> to latest upstream"
```

Installer-flag wiring for these integrations is tracked in `PRD.md` as remaining Phase 2.5 work.
