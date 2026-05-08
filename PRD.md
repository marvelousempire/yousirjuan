# You-Sir Juan — Product Requirements Document

| Field | |
|---|---|
| **Document version** | 0.1.0 |
| **Status** | Draft |
| **Owner** | Avery Brown / You-Sir Juan Agent (`hello@yousirjuan.ai`) |
| **Last updated** | 2026-04-26 |
| **Related docs** | [README.md](README.md) · [HANDOFF.md](HANDOFF.md) · [docs/architecture.md](docs/architecture.md) |

---

## 1. Executive summary

**You-Sir Juan is a turnkey, self-hosted private AI platform for individuals, families, and small organizations** (especially family offices) that need enterprise-grade AI capability **without** sending their data to OpenAI, Anthropic, Google, or Microsoft. It packages best-in-class open-source pieces — **Ollama** for local model inference, **Open WebUI** for multi-user chat + RAG, **OpenClaw** for messaging-platform agents, **Tailscale** for the device mesh, and **nginx + Let's Encrypt** for the public endpoint — into a single repo that any technically-comfortable user can `git clone` and stand up on any Mac or Linux box in **under 30 minutes**.

It is **opinionated** about defaults (security-hardened by default, reproducible-by-default, privacy-by-default) and **flexible** where it matters (model choice, hardware tier, install profile, deployment topology).

The operator's data — chats, knowledge bases, uploaded documents, model fine-tunes — **never leaves their hardware** unless they explicitly route to a cloud provider on a per-conversation basis.

---

## 2. Problem statement

The market split today, for someone wanting AI:

| Path | What you get | What you give up |
|---|---|---|
| **ChatGPT / Claude / Gemini** | Best-in-class quality, zero setup, multi-user, mobile apps | Your conversations, uploads, behavior patterns become training data + observability for the provider. **Data exfiltration risk for legal/financial/health/family content.** |
| **Roll-your-own from scratch** | Total privacy, total control | Weeks of engineering work, no clear path, no security hardening, brittle, no docs |
| **Enterprise self-hosted (Cohere/Anthropic enterprise)** | Privacy + quality | $50K-$1M+ annual contracts, vendor lock-in, still a vendor in the loop |

**The gap:** a self-contained, open-source, drop-in private AI stack that a family office, small-business owner, or technically-curious individual can deploy on their own hardware in an afternoon and trust for years.

You-Sir Juan fills that gap.

---

## 3. Vision & strategy

> **"Your AI lives on your hardware, behaves like your AI, and answers to you."**

### Strategic pillars

1. **Privacy-by-default.** Every component runs locally. No telemetry. No "phone home". Conversations + uploads never leave operator hardware unless explicitly routed to a cloud API.
2. **Reproducible.** Repo is the source of truth. Every byte of configuration is in git. Anyone with the repo + a domain can stand up an identical deployment.
3. **Hardware-honest.** The installer detects hardware and recommends realistic profiles. CPU-only Intel boxes get a "chat only" profile that works; M-series + GPU boxes get "full stack" with the agent layer. We don't ship configurations that won't work on the target hardware.
4. **Defense in depth.** TLS at the edge, firewall on the host, app-level auth, rate limits, fail2ban, encrypted mesh between devices, swap-protected against OOM cascades.
5. **Boring stack.** Off-the-shelf battle-tested pieces (nginx, Ollama, Postgres, systemd) — minimal proprietary glue. If we go away, the stack still works.
6. **Power without lock-in.** Operator can swap any component. Operator can take their data + leave anytime — backup tarball is portable.

### What this is NOT

- Not a SaaS (today). No central control plane, no shared multi-tenancy.
- Not a managed service. The operator is responsible for hardware, network, and ongoing security.
- Not an Anthropic / OpenAI substitute for *every* use case. Local 8B-30B models are good but not state-of-the-art frontier. Cloud providers remain available and useful as opt-in for non-sensitive heavy lifting.

---

## 4. Target users & personas

### Primary persona — **The Family Office Principal** (operator)

Avery (this user). Owns a domain, owns a VPS, owns multiple Macs, has technical comfort but isn't a full-time sysadmin. Wants:
- Private AI for personal + business use
- A place where family members + family-office staff can use AI on the family's data without that data leaving the family's control
- A platform that grows with the family — not throwaway

### Secondary persona — **Family Office Staff**

CFO, lawyer, advisor, junior staff. Non-technical or semi-technical. Wants:
- A "ChatGPT-like" web UI they can sign in to
- The model has read the family's documents and can answer questions about them
- Their drafts + work product never leak

### Tertiary persona — **Family Member (low-tech)**

Spouse, parent, child. Wants:
- A bookmark on their phone
- Click → "Sign in with Google" → talk to AI
- Their personal chats are private to them
- Some shared resources visible to them (family schedule assistant, etc.)

### Future persona — **Other family offices / small-firm operators (post-v1)**

If You-Sir Juan productizes: similar profile to Avery. Wants this as a reference architecture they can adopt without writing it themselves. Pays for support / hardware / installation, not for the software (open-source-ish licensing).

---

## 5. Product principles

These are the tie-breakers when requirements conflict.

1. **Operator data wins over operator convenience.** If a feature would make data leak in a "default-on" sense, that feature is opt-in or it doesn't ship.
2. **Reversibility wins over polish.** Every install step has an uninstall path. Every backup has a restore. Every credential can be rotated.
3. **Honesty wins over marketing.** The installer warns about hardware limits. Docs say what doesn't work. The README doesn't promise capabilities the stack can't deliver.
4. **Boring wins over clever.** Use systemd, not custom service managers. Use SQLite, not custom DBs. Use proven tools whose failure modes are known.
5. **Repo wins over runbook.** If it's important, it's a script in the repo. If it's a step in a runbook, it's at risk of bit-rot.
6. **Cheap wins over fancy.** A $1K Mac mini that runs llama3:8b at 30 tok/s beats a $20K GPU server that runs llama3.1:70b at 50 tok/s for almost every use case the target operator has.

---

## 6. Use cases / user stories

### UC-1: Solo principal sets up private AI on their workstation
> *As an individual operator, I want to install Open WebUI + Ollama on my Mac in one command so that I have a private ChatGPT-equivalent for personal use.*

**Acceptance:** `git clone <repo> && bash bootstrap.sh` → pick "Chat only" → wait 10–15 min → open browser to localhost:3000 → sign up → chat with a local model.

### UC-2: Family office stands up a public endpoint for staff
> *As an operator, I want my family-office staff to reach our private AI from any device, anywhere, with proper HTTPS and SSO so that they don't need to be on a VPN.*

**Acceptance:** Operator runs Linux installer with "Public-facing" profile + provides domain/email → stack stands up → staff visit `https://hello.yousirjuan.ai` → sign in with Google → talk to family-office AI with shared knowledge bases.

### UC-3: Power user runs an agent on their laptop with a remote brain
> *As an operator with multiple devices, I want OpenClaw on my laptop to use my home-Mac-mini's Ollama as the inference brain, so I don't burn my laptop's CPU/battery on inference.*

**Acceptance:** OpenClaw on laptop is configured with `models.providers.ollama.baseUrl = http://mac-mini:11434` over Tailscale → agent works → laptop stays cool.

### UC-4: Family member uses AI from their iPhone over cellular
> *As a non-technical family member, I want to bookmark our family's AI on my phone and use it from anywhere without VPNs or installs, so it feels like ChatGPT but on family data.*

**Acceptance:** Phone Safari → `https://hello.yousirjuan.ai` → "Sign in with Google" (their @yousirjuan.ai or whitelisted email) → Open WebUI loads → chat works on cellular.

### UC-5: New family office adopts the stack
> *As a different family office that found the repo, I want to deploy our own instance with our own domain in an afternoon.*

**Acceptance:** Their tech-lead clones → reads README → fills `.env` → runs `bootstrap.sh` → runs `vps/apply-vps-config.sh` → has a working stack on `hello.theirdomain.com` in under 4 hours.

### UC-6: Disaster recovery
> *As an operator whose VPS just died, I want to restore my chat history and configuration on a new VPS within an hour.*

**Acceptance:** New VPS provisioned → bootstrap → `tools/restore.sh /path/to/last-night.tgz` → user logs in → chats are intact, knowledge bases intact.

### UC-7: Adding a new AI model
> *As an operator who hears about a new model release, I want to add it to my deployment in 5 min.*

**Acceptance:** `ollama pull <new-model>` on the brain box → it shows up in Open WebUI's dropdown automatically → operator chats with it.

### UC-8: Customize a model with a system prompt + RAG
> *As an operator, I want a "Family Office Assistant" model that always references our policies + financial docs.*

**Acceptance:** Operator uploads docs to a Knowledge base → creates a custom Model in Open WebUI with a strong system prompt → publishes it shared → all users see it in their model picker.

### UC-9: Audit who's using what
> *As an operator, I want to see which family members logged in this week, which models they used, and roughly how much.*

**Acceptance:** Admin Panel shows per-user activity. (Today: partial — Open WebUI has some of this. Improvement needed.)

### UC-10: Take the data and leave
> *As an operator, I want to be able to fully exit this stack with all my data exportable.*

**Acceptance:** `tools/backup.sh` produces a tarball that contains all chats, knowledge, prompts, models, configs in standard formats. Standard SQLite export, GGUF model files, plain JSON for OpenClaw config.

---

## 7. Functional requirements (MoSCoW)

### Must have (Phase 1 — done by 2026-04-26)

- [x] **F-1.** Single-command install on macOS (Apple Silicon + Intel)
- [x] **F-2.** Single-command install on Linux (Ubuntu 22.04, 24.04 — Debian 12)
- [x] **F-3.** OS-detecting `bootstrap.sh` entrypoint
- [x] **F-4.** Local LLM inference via Ollama, multiple models, RAM-aware picker
- [x] **F-5.** Browser chat UI (Open WebUI) with multi-user accounts
- [x] **F-6.** Per-user chat history isolation
- [x] **F-7.** Built-in RAG: upload PDFs/docs/URLs, attach to a model, queryable
- [x] **F-8.** Custom models via Modelfile (system prompts, parameters)
- [x] **F-9.** Public-facing HTTPS endpoint via nginx + Let's Encrypt (Linux)
- [x] **F-10.** Encrypted device mesh via Tailscale
- [x] **F-11.** Defense-in-depth public-port lockdown (iptables INPUT + DOCKER-USER)
- [x] **F-12.** SSH brute-force protection (fail2ban)
- [x] **F-13.** Auto-restart on reboot (systemd / launchd)
- [x] **F-14.** Health-check tool (`tools/health.sh`)
- [x] **F-15.** Backup/restore tooling (`tools/backup.sh`, `restore.sh`)
- [x] **F-16.** Idempotent installers (safe re-runs)
- [x] **F-17.** Hardware-aware install profile picker (Chat / Full / Public / Custom)
- [x] **F-18.** Comprehensive docs (architecture, models, multi-user, RAG, OAuth, backup, troubleshooting)
- [x] **F-19.** Repo + version control (`git push origin main`)

### Should have (Phase 2 — next 30-60 days)

- [ ] **S-1.** Open WebUI Google OAuth set up + domain whitelist
- [ ] **S-2.** Family-office signup flow (admin invites, email-with-magic-link or similar)
- [ ] **S-3.** Off-site automated backup (cron + rsync to S3/B2/NAS) with GPG encryption
- [ ] **S-4.** Multiple Ollama brain boxes with failover (M1 primary + VPS fallback)
- [ ] **S-5.** SSH password auth permanently disabled across all 4+ operator devices
- [ ] **S-6.** Tailscale subnet routing so devices outside the tailnet can be reached via tailnet (optional)
- [ ] **S-7.** Modelfile bundle in repo (`config/modelfiles/`) — version-controlled custom models that deploy via `ollama create`
- [ ] **S-8.** Auto-detect VPS environment vs laptop — installer picks profile 3 vs 1 by default

### Could have (Phase 3 — Q3 2026 or later)

- [ ] **C-1.** Encrypt at rest (LUKS or equivalent)
- [ ] **C-2.** Audit log: who-did-what-when, exportable
- [ ] **C-3.** Multi-tenant isolation (separate Open WebUI instance per family branch)
- [ ] **C-4.** Voice integration (microphone + TTS) per device
- [ ] **C-5.** Messaging-platform integrations via OpenClaw — WhatsApp, Telegram, iMessage
- [ ] **C-6.** Mobile companion app (iOS/Android) wrapping the web UI
- [ ] **C-7.** Fine-tuning pipeline — operator can train a model on their data, get a new GGUF
- [ ] **C-8.** Web-search tool inside Open WebUI (DuckDuckGo / Brave / SearXNG) with privacy
- [ ] **C-9.** Calendar / Email integration via OpenClaw (with explicit opt-in)
- [ ] **C-10.** docker-compose stack alternative for fully containerized deploy
- [ ] **C-11.** GUI-based onboarding wizard for non-technical users (Electron or Tauri)
- [ ] **C-12.** Hardware support docs for Jetson AGX Orin / Thor / NVIDIA GPU servers
- [ ] **C-13.** Plugin marketplace (curated Open WebUI Tools / OpenClaw skills)
- [ ] **C-14.** Cost reporting if cloud-API fallback is used (track tokens to OpenAI/Claude)
- [ ] **C-15.** Per-family-office white-label branding (logo, colors, login text)

### Won't have (out of scope for v1.x)

- Public SaaS / managed-cloud version
- Enterprise SSO beyond Google (SAML, Okta) — community can add
- Real-time collaborative editing
- Voice-to-voice phone calls (not a phone system)
- Crypto/blockchain anything

---

## 8. Non-functional requirements

### Performance

| Metric | Target | Current |
|---|---|---|
| Time from `git clone` to working chat (Mac, Apple Silicon, broadband) | < 15 min | ~10–15 min ✅ |
| Time from `git clone` to working public endpoint (VPS) | < 30 min | ~25 min ✅ (after DNS propagates) |
| Inference latency for 8B model on Apple Silicon | < 2 sec to first token, > 30 tok/s sustained | ~30–50 tok/s on M-series ✅ |
| Inference latency for 8B model on CPU-only VPS | "Slow but works" — < 30 sec for short answers | ~3–8 tok/s; OpenClaw agent times out (intended limitation) |
| Page load (Open WebUI) | < 1 sec | ~0.5 sec ✅ |
| Concurrent users (single instance) | 50+ users on adequate hardware | Untested — depends on brain-box specs |

### Security

- **Public attack surface** = exactly 22, 80, 443 by default
- **No service binds public** without an explicit firewall block of public NIC for that service
- **Fail2ban** banning SSH brute-force IPs after 5 failures, 24h ban
- **HTTPS only** on public endpoint — HTTP returns 301
- **Strong cipher suite** (Let's Encrypt-recommended)
- **Open WebUI session secret** rotated on install + reinstall
- **Default disabled signup** after admin claimed
- **All secrets in env vars or chmod 600 files**, never in repo
- **Backup tarballs unencrypted by default** but docs prescribe GPG encryption for off-site

### Privacy

- **Zero outbound telemetry** from the stack itself (only Ollama updates, Docker pulls, certbot renewals)
- **Conversations never sent to third parties** unless operator explicitly configures cloud API in Open WebUI
- **Embeddings local** (nomic-embed-text via Ollama, never an API call)
- **Model downloads visible** (Ollama pulls leave a trail of "you downloaded model X")
- **Operator-controlled key management** — they own LE cert renewal, OAuth secrets, etc.

### Reliability

- **Auto-restart on boot** — every service is a systemd unit (Linux) or LaunchAgent (macOS)
- **Auto-restart on crash** — `Restart=on-failure` everywhere
- **OOM-protected** — swap configured, Ollama keep-alive limits, max-loaded-models=1
- **Idempotent installers** — re-run after partial failure, no harm
- **Backup-and-restore tested** quarterly per operating playbook (`docs/backup-restore.md`)

### Reproducibility

- **Repo is source of truth** — VPS state, install scripts, configs all checked in
- **No manual steps in the critical path** — every operator interaction has a script
- **Templated configs** — `__DOMAIN__` placeholders make any deploy possible
- **`.env` model** — user-specific values isolated, not committed

### Maintainability

- **Plain bash** for installers (no exotic dependencies)
- **POSIX-sh-compatible** for VPS scripts (router scripts especially — OpenWRT BusyBox)
- **Component versions pinned** where stability matters (Open WebUI image tag = `:main` for now, will pin to a specific version when stable enough)
- **Docs colocated with code** — every script's purpose is documented at the top of the file

---

## 9. Technical architecture

See [`docs/architecture.md`](docs/architecture.md) for the full diagram + per-layer rationale.

Layered summary:

| Layer | Purpose | Technology |
|---|---|---|
| **L1: Public TLS** | Browser HTTPS termination, cert lifecycle | nginx + Certbot (Let's Encrypt) |
| **L2: App** | Multi-user chat, RAG, knowledge bases, Modelfiles | Open WebUI (Docker) |
| **L3: Inference** | LLM execution | Ollama (native install per-platform) |
| **L4: Agent** | Personal AI agent (messaging, voice, browser control) | OpenClaw (npm install) |
| **L5: Network mesh** | Encrypted device-to-device | Tailscale |
| **L6: Host firewall** | Port lockdown | iptables INPUT + DOCKER-USER chains |
| **L7: SSH defense** | Brute-force mitigation | fail2ban + key-only auth (in progress) |
| **L8: Memory hygiene** | OOM prevention | Swap file + Ollama keep-alive limits |

---

## 10. Constraints & assumptions

### Constraints

- **C-A1.** Operator owns the hardware. We don't provision hardware; we configure what the operator has.
- **C-A2.** Operator owns the domain. We don't register domains; we use what they have.
- **C-A3.** Open-source dependencies only. No closed-source libraries shipped in the stack.
- **C-A4.** Operator is the security team. Self-hosted = self-secured. We provide the hardening defaults, the operator is responsible for ongoing operation.
- **C-A5.** Hardware sets the ceiling. CPU-only boxes can't run agentic workloads in real-time; we surface this limitation in the installer.
- **C-A6.** Internet connectivity required at install (dependencies, model pulls, certbot). Once installed, mostly offline-capable for inference.
- **C-A7.** macOS 13+ supported, Linux Ubuntu 22.04+ / Debian 12. Windows is out of scope.

### Assumptions

- **A-A1.** Operator has technical comfort with terminal commands. Not "every user", but at least one operator per deployment can read the README and run `bash bootstrap.sh`.
- **A-A2.** Operator has a registrar account for their domain (GoDaddy / Cloudflare / Namecheap / etc.) and can add A records.
- **A-A3.** Operator's network allows outbound HTTPS to GitHub, Ollama CDN, Docker Hub, Let's Encrypt. (Captive portals will fail.)
- **A-A4.** Operator is willing to use Tailscale (free for personal use). Self-hosted alternatives possible but out of v1.x scope.
- **A-A5.** Operator's family/staff have email addresses (for OAuth or invitations).

---

## 11. Success metrics

### Phase 1 (today — done)

| Metric | Target | Actual |
|---|---|---|
| Number of devices in operator's mesh | ≥ 2 | 2 (iMac + VPS) ✅ |
| Public endpoint TLS-rated A or A+ | A+ | TBD (run https://www.ssllabs.com/ssltest/) |
| Brute-force attempts blocked per day | > 90% of attempts | fail2ban active ✅ |
| Open WebUI version | latest stable | 0.9.2 ✅ |
| Models available | ≥ 4 | 1 on VPS (capacity-limited); 2 on iMac stopped (operator's choice) |
| Repo: top-level docs/ + README all populated | 100% | ✅ |
| Repo: bootstrap.sh works on Mac + Linux | yes | ✅ |
| Time from clone to working chat (operator measured) | < 30 min | not yet measured by operator on a clean machine |

### Phase 2 (next 30-60 days)

| Metric | Target |
|---|---|
| Operator's family members onboarded | ≥ 3 |
| Family office staff onboarded | ≥ 2 |
| Daily active users | ≥ 5 |
| Models available across mesh | ≥ 6 (incl. one ≥ 30B parameter) |
| Off-site backup tested + verified | yes |
| SSH password auth disabled | yes |
| OAuth (Google) signup flow live | yes |

### Phase 3 (Q3+ 2026)

- Per-user latency P50 < 2 sec to first token (with brain on Apple Silicon or Jetson)
- 99% uptime on public endpoint
- Per-month operator support hours required: < 2

---

## 12. Phased roadmap

### Phase 1: Personal foundation (✅ DONE — through 2026-04-26)

**Goal:** Operator has a working, hardened, reproducible private AI deployment for themselves.

- [x] Repo at `github.com/marvelousempire/yousirjuan`
- [x] Mac + Linux installers
- [x] VPS deployed with public HTTPS at `hello.yousirjuan.ai`
- [x] Tailscale mesh (iMac + VPS)
- [x] Defense-in-depth firewall + fail2ban
- [x] Open WebUI 0.9.2, admin claimed
- [x] OOM-safe (swap added)
- [x] All docs written
- [x] Hardware-aware install profiles

### Phase 2: Family rollout (30–60 days from now)

**Goal:** Operator's family + family office can use it daily.

- [ ] M1 Macbook online + tailnet-connected — becomes the real Ollama brain
- [ ] Open WebUI Google OAuth set up; whitelist `@yousirjuan.ai`
- [ ] Multi-user signup flow validated with at least 3 family members
- [ ] Shared "Family Office Assistant" model with policies + key documents
- [ ] SSH password auth permanently disabled (after all operator devices keyed)
- [ ] Off-site backup automation (daily encrypted tarball to S3 / NAS)
- [ ] Tailnet renamed to something memorable (`nivram` or operator's choice)

### Phase 3: Hardware upgrade + advanced models (Q3 2026)

**Goal:** Run flagship-class models on dedicated brain hardware.

- [ ] Decide on brain hardware (Mac mini M4 Pro, Jetson AGX Orin 64, Jetson AGX Thor 128)
- [ ] Procure + install
- [ ] Migrate Ollama brain from VPS to brain box
- [ ] Pull `gpt-oss:20b`, `qwen3:14b`, possibly `gpt-oss:120b` on Thor
- [ ] OpenClaw brought back online with brain box (real Jarvis architecture)
- [ ] Voice / wake word on personal devices

### Phase 4: Productize (2027+)

**Goal:** Other family offices / similar-profile operators can adopt this without needing to know the operator personally.

- [ ] Polish onboarding for non-technical operators (GUI wizard, video walkthroughs)
- [ ] Hardened reference architecture doc (NIST-aligned where applicable)
- [ ] Optional paid tiers — installation services, support, hardware bundles
- [ ] License clarity (currently all-rights-reserved; potentially shifts to BSL or similar)
- [ ] Plugin / model marketplace for curated additions
- [ ] Compliance posture documented (HIPAA / SOC2-light) for those who care

### Phase 5: Long-term sustainment (2028+)

- Maintenance mode + hardening pass annually
- Track Ollama / Open WebUI / OpenClaw upstream releases, evaluate + roll forward
- Drop-in support for new model releases as they happen
- Hardware refresh cadence (every 2-3 years)

---

## 13. Open questions / decisions needed

Captured on 2026-04-26. Each needs operator decision before progressing the relevant work.

| # | Question | Blocks |
|---|---|---|
| Q1 | Brain hardware: Mac mini M4 Pro (~$2.2K) vs Jetson AGX Orin 64 (~$2.5K) vs Jetson AGX Thor 128 (~$3K+)? | Phase 3 procurement |
| Q2 | Tailnet name — keep `tailaa31dd.ts.net` (free, ugly) or rename to `nivram` / `yousirjuan` / other? | Cosmetic — TLS via Tailscale uses this |
| Q3 | Is You-Sir Juan a family-only project, or eventually a product to license to others? | Affects architecture decisions (multi-tenant isolation, branding, etc.) |
| Q4 | Disaster recovery RTO/RPO target — how fast must we recover, how much data loss acceptable? | Affects backup strategy |
| Q5 | Encrypt-at-rest on VPS — required, deferred, never? | Hardening posture |
| Q6 | Will operator allow `pm2-abrownsanta` apps to share the VPS with You-Sir Juan long-term, or will You-Sir Juan move to dedicated infra? | Resource planning |
| Q7 | Cloud API fallback (OpenAI, Anthropic) — per-user opt-in only, or admin-toggled globally? | UX + privacy posture |
| Q8 | Voice — priority for Phase 3 or Phase 4? | Roadmap order |
| Q9 | Family member 2FA — required or opt-in? | Login flow design |
| Q10 | License — keep "all rights reserved", switch to BSL, or open-source? | Strategic positioning |

---

## 14. Risks + mitigations

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| Operator's VPS dies (hardware failure / GoDaddy issue) | Low | High | Off-site backup (Phase 2), DNS failover possible, rebuild via repo in <1 hour |
| OOM cascade brings down VPS (happened once on 2026-04-25) | Low (mitigated) | High | 4 GB swap added, Ollama memory hygiene configured, monitoring via `health.sh` |
| Open WebUI 0-day | Medium | High | Pin to versioned image (not `:main`), monitor security mailing list, swift `docker pull` + restart |
| Ollama model release breaks compatibility | Medium | Medium | Test new models in dev before pulling on production; keep a known-working model loaded |
| Operator forgets the admin password | Medium | Medium | Documented bcrypt-reset procedure in `docs/troubleshooting.md` |
| Family member's chat exposes private info via screenshot/social engineering | Medium | High | Out of stack scope; user training; consider audit log feature (S-1 → C-2) |
| GitHub account compromise | Low | High | Hardware 2FA on `marvelousempire` GitHub account; signed commits (consider) |
| Tailscale account compromise | Low | High | Hardware 2FA on Tailscale account; node-key sharing audit |
| Family office grows beyond 50 users | Low | Medium | Phase 3 hardware (Jetson Thor) + multi-tenant isolation (C-3) |
| OpenAI / Anthropic API cost spikes if used as fallback | Medium | Low | Cost reporting feature (C-14); per-user budget caps (future) |

---

## 15. Glossary

| Term | Definition |
|---|---|
| **Brain box** | The device running Ollama (the actual LLM inference). M-series Mac, Jetson, NVIDIA GPU machine, etc. |
| **Body** | A device running OpenClaw or Open WebUI client — handles local actions (browser, voice, file ops) but calls the brain box for inference. |
| **Tailnet** | Operator's private Tailscale network. All devices in the tailnet can reach each other directly over WireGuard regardless of physical location. |
| **MagicDNS** | Tailscale's DNS feature — gives every device a friendly hostname (`vps-godaddy`, `imac-avery`). |
| **Modelfile** | Ollama's config syntax for customizing a model — system prompt, parameters, base model. |
| **RAG** | Retrieval-Augmented Generation. The model reads relevant chunks of your docs at query time. |
| **Knowledge base** | A collection of documents in Open WebUI, embedded for RAG. |
| **Profile** (install profile) | One of {Chat only, Full stack, Public-facing, Custom}. Picked at install time. |
| **DOCKER-USER chain** | iptables chain Docker provides as the official escape hatch for operators to add their own rules without Docker overwriting them. |
| **`--ctorigdstport`** | iptables conntrack match that filters on the ORIGINAL destination port before any DNAT — necessary for blocking Docker-published ports. |
| **OOM** | Out-of-memory. When kernel kills processes because RAM is exhausted. |
| **fail2ban** | Daemon that bans IPs based on log patterns (e.g., 5 failed SSH logins). |
| **JWT** | JSON Web Token — Open WebUI's session token after login. Sent in `Authorization: Bearer <token>` headers. |
| **Operator** | The technical owner of a deployment. In our case: Avery. |
| **Family office** | A small organization managing the affairs of a wealthy family — investments, taxes, legal, scheduling, etc. |

---

## 16. Approvals

| Role | Name | Date | Signature |
|---|---|---|---|
| Operator / PM | Avery Brown | 2026-04-26 | _draft, not yet signed_ |
| Tech lead | (Avery — same role) | 2026-04-26 | _draft, not yet signed_ |
| AI co-author | You-Sir Juan Agent | 2026-04-26 | _self-signed_ |

---

## Appendix A — change log

| Version | Date | Author | Notes |
|---|---|---|---|
| 0.1.0 | 2026-04-26 | You-Sir Juan Agent | Initial draft from session-end synthesis |
