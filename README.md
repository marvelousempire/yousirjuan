# You-Sir Juan — Private Trainable AI Assistants

You-Sir Juan is a private AI infrastructure and service platform for building **trainable AI assistants** for families, family offices, PMAs, portfolio companies, and service teams.

The core idea is simple:

> Give each client a private AI helper they can teach — a nanny assistant, coach, trainer, family office aide, operations helper, or business agent — without requiring the client to understand RAG, models, vector databases, or agent orchestration.

Under the hood, You-Sir Juan keeps the existing private AI stack: local inference, private memory, secure networking, RAG, backups, and agent tooling. The new face of the repo is the business layer built on top of that stack.

**Your data, your memory, your assistant, your infrastructure.**

---

## What This Becomes

This repo is no longer just a self-hosted AI lab. It is the operating blueprint for a private AI service business:

1. **Families** can train AI helpers for house rules, nanny handbooks, routines, schedules, preferences, medical notes, meal rules, school details, travel routines, and household standards.
2. **Personal service teams** can train assistants for coaches, personal trainers, chefs, drivers, house managers, tutors, and care providers.
3. **Family offices** can train private agents for document intelligence, estate workflows, investment research, governance records, and advisor coordination.
4. **PMA operations** can train assistants for member onboarding, education, communications, retention, and internal playbooks.
5. **Portfolio businesses** can train marketing, sales, support, operations, and content agents using shared playbooks while keeping sensitive domains separate.

The customer should experience this as:

> “Teach your own private AI support staff.”

The system handles the technical parts: memory, storage, retrieval, access control, model routing, backups, and agent workflows.

---

## Service Vision

Each client gets a secure workspace where they can create one or more AI assistant roles:

| Assistant Type | What It Learns | Example Use |
|---|---|---|
| **Nanny Assistant** | Household rules, child routines, allergies, school pickup notes, screen-time rules | “What should the nanny do after school?” |
| **House Manager Assistant** | Vendor lists, maintenance schedules, home systems, recurring tasks | “Who fixes the pool pump and what is our process?” |
| **Personal Trainer / Coach** | Goals, training history, diet preferences, injuries, weekly plans | “Build this week’s workout plan.” |
| **Family Office Assistant** | Trust-domain documents, entity records, advisor notes, policies | “Find the current estate planning checklist.” |
| **PMA Assistant** | Member onboarding, agreements, events, communications | “Draft a member welcome sequence.” |
| **Portfolio Marketing Agent** | Brand voice, offers, customer research, campaigns, wins, failures | “Write a landing page using our proven hooks.” |

The client teaches the assistant by uploading or entering:

- handbooks
- rules
- checklists
- contracts
- SOPs
- schedules
- preferences
- playbooks
- transcripts
- onboarding guides
- family or business context files

The platform turns those into private searchable memory.

---

## What This Is Technically

A reproducible deployment of:

- **Ollama** — local LLM inference for private utility models
- **Open WebUI** — ChatGPT-style multi-user web app
- **OpenClaw** — optional messaging-app assistant layer
- **Ruflo** — agent orchestration, memory, RAG, observability, and workflows
- **marketingskills** — marketing and growth skill pack for portfolio businesses
- **Tailscale / WireGuard** — encrypted private mesh between approved devices
- **nginx + Let’s Encrypt** — public HTTPS endpoint when needed
- **fail2ban + iptables** — defense-in-depth firewall
- **NAS / DAS / NVMe storage** — private memory, documents, backups, and model files
- **Jetson Thor / Mac / VPS nodes** — local compute roles for inference, orchestration, and always-on services

Deployable on macOS or Linux from a single bootstrap script. Idempotent — safe to re-run.

---

## Business Model

You-Sir Juan can be packaged as a private AI assistant service:

| Layer | What The Client Pays For |
|---|---|
| **Workspace setup** | Secure client workspace, assistant roles, onboarding session |
| **Private memory storage** | Stored documents, transcripts, profiles, handbooks, vector indexes |
| **Assistant roles** | Nanny, coach, trainer, house manager, FO aide, marketing agent, etc. |
| **Managed AI hosting** | Compute, uptime, model serving, backups, maintenance |
| **Premium workflows** | Document intelligence, content generation, task automation, reporting |
| **Compliance / privacy tier** | Stricter data separation, audit logs, offline/local-only mode |

Core pricing concept:

- charge per workspace
- charge per assistant role
- charge for storage used
- charge for managed hosting and support
- charge for custom workflows and integrations

See:

- `docs/ai-assistant-business-model.md`
- `docs/customer-ai-memory-architecture.md`
- `docs/private-ai-network-handoff.md`

---

## Trust-Domain Design

The system is built around strict separation:

| Domain | Use | Memory Rule |
|---|---|---|
| **Family / Household** | nanny, home, care, routines | never mixed with other clients |
| **Family Office** | wealth, estate, tax, governance | highest sensitivity; local-first only |
| **PMA** | members, education, communications | separate from FO |
| **Portfolio Business** | marketing, operations, sales | can use shared business playbooks |
| **Shared Learning Layer** | wins, failures, vendor lists, templates | never receives FO/private household data |

Critical rule:

> No `fo:*`, household, nanny, child, legal, tax, medical, or private family data flows into shared business memory.

---

## Install Profiles

The installer detects hardware and recommends a profile, but you can override:

| Profile | What you get | Recommended for |
|---|---|---|
| **1 — Chat only** | Ollama + Open WebUI | Any machine, even CPU-only / low-RAM |
| **2 — Full stack** | Chat stack + OpenClaw | Apple Silicon Mac or Linux GPU box |
| **3 — Public-facing** | Stack + nginx + Let’s Encrypt + firewall | VPS with public IP and DNS |
| **4 — Custom** | Pick each component | Power users |
| **5 — Client assistant platform** | workspace templates, memory docs, assistant roles, service model | You-Sir Juan business build |

---

## Quick Start

### macOS

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
bash bootstrap.sh
```

Or double-click:

```text
command-launchers/Install Private AI.command
```

### Linux / VPS

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
bash bootstrap.sh
```

Tested target family: Ubuntu / Debian style hosts.

### VPS public endpoint

```bash
sudo DOMAIN=hello.yousirjuan.ai EMAIL=hello@yousirjuan.ai \
  bash vps/apply-vps-config.sh
```

This stands up nginx + Let’s Encrypt + fail2ban + iptables lockdown.

---

## Repository Layout

```text
yousirjuan/
├── README.md
├── LICENSE
├── .env.example
├── .gitignore
├── bootstrap.sh
│
├── installers/
│   ├── macos.sh
│   └── linux.sh
│
├── vps/
│   ├── apply-vps-config.sh
│   ├── nginx-vhost.conf.template
│   ├── fail2ban-sshd.local
│   ├── ollama-systemd-override.conf
│   └── iptables-public-lockdown.sh
│
├── tools/
│   ├── health.sh
│   ├── backup.sh
│   ├── restore.sh
│   ├── uninstall.sh
│   ├── glinet-router-setup.sh
│   ├── init-portfolio-business.sh
│   └── init-client-assistant.sh
│
├── command-launchers/
│   ├── Install Private AI.command
│   ├── Check Health.command
│   ├── Backup.command
│   ├── Restore.command
│   ├── Uninstall.command
│   └── Configure Router.command
│
├── config/
│   └── openclaw.json.template
│
├── docker/
│
└── docs/
    ├── architecture.md
    ├── ai-assistant-business-model.md
    ├── customer-ai-memory-architecture.md
    ├── private-ai-network-handoff.md
    ├── adding-models.md
    ├── multi-user.md
    ├── rag-and-knowledge.md
    ├── modelfile-customization.md
    ├── oauth-google.md
    ├── backup-restore.md
    └── troubleshooting.md
```

---

## What You Get Out Of The Box

| Capability | Status |
|---|---|
| Local LLM inference | Ollama and local model support |
| Multi-user chat UI | Open WebUI |
| Private assistant roles | nanny, coach, trainer, FO aide, PMA aide, marketing agent |
| Per-client memory | isolated RAG namespaces and workspace folders |
| Per-user uploaded knowledge | documents, PDFs, notes, SOPs, handbooks |
| Agent orchestration | Ruflo / MCP-driven workflow layer |
| Marketing skill layer | marketingskills for portfolio companies |
| Cloud fallback | allowed only by policy and never for FO/private household data |
| Public HTTPS endpoint | nginx + Let’s Encrypt |
| Private mesh | Tailscale / WireGuard |
| Attack-surface lockdown | iptables and fail2ban |
| Backup + restore | tarball scripts and planned NAS/B2 workflows |
| Always-on assistant option | OpenClaw on Mac mini / VPS / dedicated node |

---

## Customer Workspace Pattern

Each customer should get a folder or tenant namespace like:

```text
clients/
└── smith-family/
    ├── client-profile.md
    ├── assistants/
    │   ├── nanny/
    │   │   ├── assistant-profile.md
    │   │   ├── house-rules.md
    │   │   ├── child-routines.md
    │   │   └── safety-notes.md
    │   ├── house-manager/
    │   └── coach/
    ├── documents/
    ├── memory-policy.md
    └── CLAUDE.md
```

Each assistant gets:

- a role
- memory boundaries
- allowed documents
- prohibited topics
- escalation rules
- storage policy
- optional cloud policy

---

## Example Memory Namespaces

```text
client:smith-family:household:rules
client:smith-family:household:routines
client:smith-family:nanny:handbook
client:smith-family:children:school
client:smith-family:coach:fitness
client:smith-family:vendors:approved
```

Family office examples:

```text
fo:legal:trusts
fo:tax:current-year
fo:investments:active
fo:advisors
```

Portfolio examples:

```text
pma:members:active
shared:playbooks:wins
shared:vendors:approved
business-name:campaigns
business-name:customers
```

---

## Security Posture

This is private infrastructure, not an open public chatbot.

Defaults assume:

- known users
- isolated client workspaces
- approved devices
- encrypted private mesh
- strict public-port exposure
- private memory boundaries

Hardened or planned controls:

- SSH key-only auth
- fail2ban brute-force defense
- Docker port lockdown
- Open WebUI signup closure after admin claim
- rotated `WEBUI_SECRET_KEY`
- HTTPS-only endpoint
- security headers
- per-client namespace isolation
- no cloud use for FO/private household data
- audit logs through Ruflo observability
- off-site backup roadmap
- encrypted-at-rest storage roadmap

---

## Privacy Model

| Data | Default Location |
|---|---|
| Client prompts and uploads | private workspace storage |
| Assistant memory | isolated vector namespace |
| Local model inference | trusted hardware |
| Family office data | local-only, no cloud APIs |
| Portfolio marketing data | may use allowed cloud APIs if policy permits |
| Shared business playbooks | portfolio shared layer only |
| Backups | NAS, offline drive, encrypted off-site bucket |

---

## Development Flow

```text
edit on laptop -> git commit -> git push -> pull on server -> re-run bootstrap.sh
```

Every script should remain idempotent.

---

## Product Direction

The repo should grow toward these deliverables:

1. Client workspace generator.
2. Assistant role templates.
3. RAG namespace manager.
4. Storage usage meter.
5. Client billing hooks.
6. Private upload portal.
7. Assistant training wizard.
8. Audit log viewer.
9. Backup and recovery dashboard.
10. FO/PMA/portfolio separation policy engine.

---

## License

Internal use only. See `LICENSE`.
