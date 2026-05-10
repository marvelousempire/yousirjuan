# You-Sir Juan — Session Handoff

**Session window:** 2026-04-24 → 2026-05-08 (multi-day)
**Latest update:** 2026-05-08 — added marketing website (public repo `yousirjuan-ai`), signed-installer pipeline, Docker hardening, OpenClaw-router container, capability-based agent broker scaffold.
**Operator on this Mac:** averygoodman (human is "Avery Brown")
**Identity for Git/AI:** "You-Sir Juan Agent" — hello@yousirjuan.ai
**GitHub account:** `marvelousempire`
**Tailscale account / tailnet owner:** `marvelousempire@`

This document is the complete state-of-the-world. Read top-to-bottom for new joiners; jump to **Outstanding** to keep building.

---

## 1. Where everything lives

### Hardware in the mesh

| Device | Role | OS / Specs | Tailscale IP | LAN/Public |
|---|---|---|---|---|
| **iMac (this machine)** | Operator workstation. Running OpenClaw experiments. Currently disabled. | Intel i5-7500 (2017), 64 GB RAM, macOS 13.7.8 | `100.84.107.1` (`imac-avery`) | LAN only |
| **GoDaddy VPS** | Production. Open WebUI + Ollama + Tailscale + nginx + many of operator's other apps. | Ubuntu 24.04, 4 vCPU, 7.8 GB RAM (+ 4 GB swap added), 193 GB disk | `100.91.70.100` (`vps-godaddy`) | Public IP `72.167.151.251` (FQDN: `251.151.167.72.host.secureserver.net`) |
| **M1 Macbook** | NOT YET on tailnet. Will become the real Ollama brain when set up. | Apple Silicon, unknown RAM | — | — |
| **2 other computers** | NOT YET on tailnet, SSH password auth not yet disabled (waiting on their keys). | One Mac named "nivram", one unknown | — | — |
| **GL.iNet Flint 2 (MT6000)** | User's home router. NOT yet AI-configured. | OpenWRT-based | — | LAN |
| **GL.iNet Slate AX (AXT1800)** | User's travel router. NOT yet AI-configured. | OpenWRT-based | — | — |

### Domains + DNS

| Hostname | Points at | Purpose |
|---|---|---|
| `hello.yousirjuan.ai` | A → `72.167.151.251` (public IP of VPS) | Public Open WebUI endpoint with Let's Encrypt HTTPS |
| `admin.readyplay.app` | nginx vhost on VPS → PM2 :3002 | Operator's existing app (untouched) |
| `api.readyplay.app` | nginx vhost on VPS → PM2 :3001 | Operator's existing app (untouched) |
| `marketing.readyplay.app` | nginx vhost on VPS → PM2 :3003 | Operator's existing app (untouched). **Has pre-existing DATABASE_URL build issue — see §6** |
| `averyhandyman.com` / `www.averyhandyman.com` | nginx vhost on VPS → PM2 :3110 | Operator's existing app (untouched) |
| `vps-godaddy.tailaa31dd.ts.net` | MagicDNS (Tailscale) | Friendly name for VPS within mesh |
| `imac-avery.tailaa31dd.ts.net` | MagicDNS (Tailscale) | Friendly name for iMac within mesh |
| `*.yousirjuan.ai` | Owned, DNS managed at registrar (location TBD by operator) | Domain operator controls |
| `*.nivram.ai` | Owned, but NOT used (user changed mind to yousirjuan.ai) | Operator owns; available |

### Network surface

**Public ports on VPS (intentional):** 22 (SSH, fail2ban-protected), 80/443 (nginx for the readyplay/yousirjuan/averyhandyman vhosts).

**Blocked on public NIC, allowed on `tailscale0`:** 3000 (Open WebUI), 11434 (Ollama), 2224 (Nydus), 8081-8113 (WordPress staging — currently stopped), 8088-8090 (SundayApp range), 18789 (OpenClaw gateway — when running).

Implementation:
- `iptables -A INPUT -i eth0 -p tcp --dport <port> -j DROP` for host services
- `iptables -A DOCKER-USER -i eth0 -p tcp -m conntrack --ctorigdstport <port> -j DROP` for Docker-published ports (uses `--ctorigdstport` because Docker DNATs before FORWARD)
- Persisted via `iptables-persistent`

### Repo

| Thing | Where |
|---|---|
| **Private** source (`yousirjuan`) | https://github.com/marvelousempire/yousirjuan — full stack, scripts, VPS templates, broker, internal/handoff docs; keep non-public material here only |
| **Public** marketing + downloads (`yousirjuan-ai`) | https://github.com/marvelousempire/yousirjuan-ai — Next.js site ([yousirjuan.ai](https://yousirjuan.ai)), customer copy, Release assets for signed `.pkg` / install commands |
| Messaging alignment | [docs/customer-facing-messaging.md](docs/customer-facing-messaging.md) — keep in sync when changing hero, features, privacy table, or installer URLs |
| Local clone | `/Users/averygoodman/Developer/yousirjuan/` (operator Mac); any path on other machines |
| Default branch | `main` |
| Auto-renew + clone-anywhere ready | Yes — `git clone … && bash bootstrap.sh` |

---

## 2. Credentials + secrets registry

| What | Where it lives | Notes |
|---|---|---|
| Open WebUI admin | `book@averyhandyman.com` (operator) | Bcrypt-hashed in SQLite at `/var/lib/docker/volumes/open-webui/_data/webui.db`. Operator knows the password. |
| Open WebUI `WEBUI_SECRET_KEY` | Env var on the running container | 64-char random hex, generated at install time. Survives container recreation if preserved via `docker inspect`. **Do NOT commit.** |
| OpenClaw gateway token | `~/.openclaw/openclaw.json` on each device | Auto-generated at install (24-byte hex). New per device. |
| Ollama API | `~/.ollama/id_ed25519` (private key for model registry) | Default, no auth changes. |
| Let's Encrypt cert (`hello.yousirjuan.ai`) | `/etc/letsencrypt/live/hello.yousirjuan.ai/{fullchain,privkey}.pem` | Auto-renewed by `certbot.timer`. Expires `2026-07-23`. |
| Tailscale auth | Tailscale's own coordinator (Google/Microsoft/etc. SSO) | Operator authed via browser on `marvelousempire@`. |
| GitHub auth | `gh auth status` shows `marvelousempire` (HTTPS via keyring) | Persists in macOS Keychain. |
| Git identity | `~/.gitconfig`: name "You-Sir Juan Agent", email `hello@yousirjuan.ai` | Used for all commits. |
| Old basic-auth password (`hello:UrFv7nTHvyG9JSxoupzasBWE`) | **OBSOLETE** — basic auth was removed when it conflicted with Open WebUI's Bearer-token auth. | If anything still references it, that's stale. |
| GoDaddy admin (VPS reboot panel) | https://account.godaddy.com → Servers | Operator has account. |

**Files to never commit (in `.gitignore`):** `*.key`, `*.pem`, `htpasswd`, `.env`, `**/google_oauth`, `**/anthropic_key`, `**/openai_key`, `*-secrets.json`.

---

## 3. Architecture as currently deployed

```
┌─────────────────────────────────────────────────────────────────┐
│  Public internet                                                │
│  • Family browsers / phone hit https://hello.yousirjuan.ai      │
│  • Bots brute-force SSH on :22 (fail2ban catches them)          │
└────────────────────────────────┬────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  VPS  72.167.151.251  (Ubuntu 24.04, 7.8 GB RAM + 4 GB swap)    │
│                                                                 │
│  nginx :80/:443 ──► HTTPS reverse proxy (Let's Encrypt)         │
│                     • hello.yousirjuan.ai → 127.0.0.1:3000      │
│                     • admin/api/marketing.readyplay.app → :30xx │
│                     • averyhandyman.com → :3110                 │
│                                                                 │
│  Open WebUI (Docker) :3000 (loopback + tailnet only)            │
│      ▲                                                          │
│      │ HTTP                                                     │
│      │                                                          │
│  Ollama :11434 (0.0.0.0; loopback + tailnet, public-blocked)    │
│      • llama3.2:latest (only model loaded, OLLAMA_KEEP_ALIVE=5m)│
│                                                                 │
│  PM2 (operator's other apps): readyplay-admin/api/marketing,    │
│      vhms-marketing, sunday-framework, hive-console             │
│                                                                 │
│  Other Docker containers (operator's): sunday-postgres,         │
│      sunday-redis, 44 WordPress staging sites (stopped)         │
│                                                                 │
│  Auto-start at boot: nginx, mysql, postgres, redis, docker,     │
│      ollama, tailscaled, fail2ban, pm2-abrownsanta, certbot     │
│                                                                 │
│  Defenses: fail2ban (24h ban after 5 failed SSH), iptables      │
│      INPUT chain + DOCKER-USER chain, swap=4GB+swappiness=10    │
└────────────────────────────────┬────────────────────────────────┘
                                 │ Tailnet (WireGuard, encrypted)
                                 │ MagicDNS = .tailaa31dd.ts.net
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │  iMac (Intel)          │
                    │  100.84.107.1          │
                    │  imac-avery            │
                    │                        │
                    │  Tailscale GUI signed  │
                    │     in.                │
                    │                        │
                    │  OpenClaw installed    │
                    │  but NOT running.      │
                    │  (Tested → too slow on │
                    │   VPS CPU. Stopped.)   │
                    │                        │
                    │  Reaches:              │
                    │  • vps-godaddy:3000    │
                    │  • vps-godaddy:11434   │
                    │  • vps-godaddy:8081-13 │
                    └────────────────────────┘
```

---

## 4. What's working today

| ✅ | Component | Notes |
|---|---|---|
| ✅ | https://hello.yousirjuan.ai (public) | HTTPS via Let's Encrypt, nginx reverse proxy → Open WebUI |
| ✅ | Open WebUI 0.9.2 (latest) | Multi-user app on VPS. Admin: `book@averyhandyman.com`. Signups disabled. |
| ✅ | Ollama on VPS | One model: `llama3.2:latest`. Bound to 0.0.0.0, public-firewalled. |
| ✅ | Tailscale mesh | iMac + VPS connected. MagicDNS = `vps-godaddy`, `imac-avery`. Owner: marvelousempire@. |
| ✅ | nginx vhosts for operator's apps | admin/api/marketing.readyplay.app, averyhandyman.com — all 200/3xx |
| ✅ | fail2ban on SSH | Banning brute-forcers (10+ caught in first minute, 24h ban). |
| ✅ | iptables public-port lockdown | Tested from this Mac: tailnet:3000 → 200, public:3000 → 000 (blocked). |
| ✅ | 4 GB swap on VPS | Persisted via `/etc/fstab` + `vm.swappiness=10`. |
| ✅ | Ollama memory hygiene | `OLLAMA_KEEP_ALIVE=5m`, `MAX_LOADED_MODELS=1`, `NUM_PARALLEL=1`. |
| ✅ | Repo at github.com/marvelousempire/yousirjuan | 3 commits, all docs written, both installers + VPS scripts. |
| ✅ | Hardware-aware install profiles | Wizard auto-recommends Chat-only / Full / Public-facing / Custom. |
| ✅ | Backup tooling | `tools/backup.sh` + `tools/restore.sh`. NOT yet scheduled. |
| ✅ | Health check tooling | `tools/health.sh` (with `--infer` for round-trip). |
| ✅ | macOS double-click launchers | Install / Health / Backup / Restore / Uninstall / Configure-Router .command files. |
| ✅ | GL.iNet router setup script | `tools/glinet-router-setup.sh` — works on Flint 2, Slate AX, Brume. |

## 5. What is NOT working / is incomplete

| ❌ / ⚠️ | What | Status / why |
|---|---|---|
| ❌ | OpenClaw agent on iMac → VPS Ollama (Jarvis architecture) | **20-minute timeout.** VPS CPU is too slow for OpenClaw's heavy prompts. M1 with Metal GPU is the right brain box. |
| ❌ | Tailnet rename `tailaa31dd.ts.net` → `nivram.ts.net` | Operator never clicked through in Tailscale admin. (Cosmetic — works without it.) |
| ❌ | Google OAuth ("Sign in with Google" for family) | Not set up. Walkthrough at `docs/oauth-google.md` ready when operator wants it. |
| ❌ | M1 Macbook on tailnet | Not yet — operator hasn't set up M1. Becomes the real brain when done. |
| ❌ | SSH password auth permanently disabled | Reverted because 2 of operator's other computers don't have keys uploaded yet. fail2ban is the current bandaid. |
| ⚠️ | `marketing.readyplay.app` build pipeline | **Pre-existing operator app issue, NOT caused by this work.** Build emits `Error: DATABASE_URL not set` for `/api/waitlist/guardian-consent` route during prerender. Site loads (returns 200) but the build is technically broken. Operator needs to set `DATABASE_URL` in build-time env (e.g. dotenvx or PM2 `--env`). |
| ⚠️ | 44 WordPress staging containers | All stopped (saved 1.5 GB RAM). Will stay stopped until operator wants to review them. Re-start with `docker start <container-name>`. |
| ⚠️ | Open WebUI shared knowledge / OAuth / Modelfiles | Documented in `docs/` but not yet configured. |
| ⚠️ | Off-site backup automation | Manual `tools/backup.sh` works, but no cron yet. |
| ⚠️ | Encrypt VPS disk at rest (LUKS) | Not done. Family-office threat model dependent. |

---

## 6. Pre-existing issues found in operator's environment (not introduced by this work)

These existed before we started; flagged for transparency. Operator's call whether to fix.

1. **VPS had ZERO swap configured** — root cause of the OOM cascade we triggered. Now fixed (4 GB swap added).
2. **Open WebUI was publicly bound to `0.0.0.0:3000` with NO admin set** — this allowed an automated scanner (`ccfaker@faker.com`, signed up `2026-01-04`) to claim the admin slot and lock signups. Operator confirmed not them; we deleted the user, rotated `WEBUI_SECRET_KEY`, re-enabled signups, operator claimed the admin slot, then disabled signups again.
3. **`PasswordAuthentication yes`** in sshd_config + **no fail2ban** + **19,189 failed SSH attempts in 7 days** — public IP is being brute-forced relentlessly. fail2ban now installed and banning. Long-term: disable password auth (blocked on the 2 other computers' keys).
4. **MySQL bound to `0.0.0.0:3306` AND `:33060`** — exposed admin protocol publicly. Now bound to `127.0.0.1` only.
5. **Docker port publishing bypasses UFW** — Docker manipulates iptables directly; published ports are reachable even with UFW deny. Solved with `DOCKER-USER` chain `--ctorigdstport` rules.
6. **`readyplay-marketing` build pipeline** — environment variable not set during build (see above).
7. **23 WordPress staging sites + their nginx fronts** all bound to public ports 8081–8113 with no auth. Now blocked from public NIC; tailnet-only. Operator can rebuild access when needed.

---

## 7. The full session timeline

### Day 1 (2026-04-24)

**Morning — Initial exploration**
- Operator wanted to install "openclaw" + Ollama + a small model on the iMac.
- Verified `openclaw` is the real GitHub project at https://github.com/openclaw/openclaw.
- Detected Intel i5-7500 — flagged that CPU-only Ollama would be slow and OpenClaw's agent layer would time out.

**Mid-morning — First install attempt**
- Started `brew install ollama colima docker` in background. Brew tried compiling Go from source (no bottle for macOS 13 Intel) — would have taken hours.
- Killed it. Switched to Ollama's official prebuilt zip (`Ollama-darwin.zip`).
- Installed Colima + Docker via brew (those had bottles).
- Pulled `gemma2:2b` (1.6 GB) and `llama3.2:3b` (2 GB).
- Started Open WebUI Docker container on `:3000`, healthy.
- npm-installed OpenClaw to user-prefix `~/.npm-global` (avoids sudo / EACCES).
- Hit `typebox/build/index.mjs` packaging bug in OpenClaw — patched by copying from a clean `npm install typebox@1.1.33`.

**Afternoon — OpenClaw debugging**
- OpenClaw gateway started, but agent inference timed out repeatedly.
- Root cause #1: bogus default model `gemma4` (which doesn't exist) in OpenClaw's auto-generated config — fixed.
- Root cause #2: OpenClaw requires ≥16k context but `gemma2:2b` only has 8k.
- Root cause #3: `llama3.2:3b` at full 131k context allocates 14 GB KV cache — fine for RAM but glacial on CPU. Capped to 32k.
- Even at 32k context, OpenClaw's agent prompts exceeded what Intel CPU could process in any reasonable time. Eventually concluded: OpenClaw + this hardware = unusable. Architectural mismatch.
- Pivoted: Open WebUI alone for chat. OpenClaw shelved until M1.

**Evening — Build the install package**
- Created `/Users/averygoodman/Developer/private-ai-package/`:
  - `install.sh` — full macOS installer
  - `health.sh` — status check
  - `backup.sh` / `restore.sh` — Open WebUI volume + OpenClaw config snapshots
  - `uninstall.sh` — clean teardown
  - `glinet-router-setup.sh` — for Flint 2 / Slate AX
  - `*.command` — double-clickable Finder launchers
  - `openclaw.json.template` — config carry-over template
  - `README.md` — initial overview

**Late evening — VPS discovery + security audit**
- Operator mentioned VPS at `251.151.167.72.host.secureserver.net` (GoDaddy hosting).
- ssh-copy-id to install our key.
- Audit found: Ubuntu 24.04, 7.8 GB RAM, 4 vCPU, Open WebUI already running publicly, ~50 Docker containers (mostly client WordPress staging), nginx serving real client sites (`readyplay.app`, `averyhandyman.com`).
- **Found intruder admin** in Open WebUI: `ccfaker@faker.com`. Captured evidence (zero chats, zero files), then deleted.
- Hardening pass: bound MySQL to loopback, installed fail2ban, removed publicly-exposed admin protocols.
- Set up Tailscale on VPS (`vps-godaddy` = `100.91.70.100`) and on the iMac (`imac-avery` = `100.84.107.1`).
- Discovered Docker port-publishing bypasses UFW; built proper `DOCKER-USER` chain rules with `--ctorigdstport` to actually block container ports from the public NIC.
- Stood up `https://hello.yousirjuan.ai` with Let's Encrypt cert + nginx reverse proxy → Open WebUI.
- Tried HTTP basic auth on top — caused 401 loops with Open WebUI's Bearer-token API calls. Removed it. Open WebUI's own login is the gate.
- Operator claimed admin (`book@averyhandyman.com`); disabled signups; rotated `WEBUI_SECRET_KEY`.
- Open WebUI upgraded from 0.6.43 → 0.9.2.
- Bound Ollama to `0.0.0.0:11434` (so containers and tailnet can reach), then explicitly blocked `:11434` on public NIC.

### Day 2 (2026-04-25)

**Morning — Repo + VPS state capture**
- Created repo `github.com/marvelousempire/yousirjuan` (private).
- Restructured package into proper layout:
  - `installers/macos.sh`, `installers/linux.sh` (new — wrote from scratch for Ubuntu/Debian)
  - `bootstrap.sh` (universal entrypoint, OS-detecting)
  - `tools/`, `command-launchers/`, `config/`, `vps/`, `docs/`
- Captured VPS state as code into `vps/`:
  - `nginx-vhost.conf.template`
  - `fail2ban-sshd.local`
  - `ollama-systemd-override.conf`
  - `iptables-public-lockdown.sh`
  - `apply-vps-config.sh` (orchestrator: takes `DOMAIN=` + `EMAIL=`, runs the lot)
- First commit pushed: `af9f1c1`.

**Late morning — OOM cascade**
- Set up "Jarvis on iMac, brain on VPS" architecture: iMac OpenClaw configured to point at `http://vps-godaddy:11434` over tailnet.
- First test: VPS Ollama returned 500 — `model requires more system memory (15.9 GiB) than is available (3.0 GiB)` (full 131k context KV cache).
- Lowered context to 16k → still 3.6 GB needed, only 2.8 GB free.
- Stopped 44 WordPress staging containers (operator confirmed they're occasional-use only) — freed 1.5 GB.
- Tried inference again. **VPS went unresponsive.** SSH timed out, ping worked. Classic OOM cascade.
  - Diagnosis: VPS had **0 swap**. When Ollama tried to load model + other processes wanted memory, kernel started killing things. Critical services (sshd) got hit.
- Operator rebooted via GoDaddy panel.

**Afternoon — Hardening + recovery**
- VPS came back. All systemd services auto-restarted.
- One operator app (`readyplay-marketing`) was in a PM2 restart loop — found pre-existing build error (`DATABASE_URL not set`). Ran `npm run build` once, got a `.next` directory enough to start. PM2 settled. Site green.
- **Added 4 GB swap file** + `vm.swappiness=10` (only swap when desperate).
- **Tightened Ollama:** `OLLAMA_KEEP_ALIVE=5m`, `MAX_LOADED_MODELS=1`, `NUM_PARALLEL=1` — releases idle models, never loads concurrently.
- All public sites (admin/api/marketing.readyplay.app, averyhandyman.com, hello.yousirjuan.ai) verified 200.

**Evening — Repo polish**
- Wrote 8 docs files (commit `031d565`):
  - `architecture.md` — full diagram + per-layer rationale
  - `adding-models.md` — catalog with sizes + RAM minimums + privacy notes (operator later edited to add gemma4 entries)
  - `multi-user.md` — admin invite + Google OAuth onboarding playbook
  - `rag-and-knowledge.md` — Open WebUI's built-in RAG, embedding setup, RAG vs fine-tuning
  - `modelfile-customization.md` — temperature/system-prompt examples (yousirjuan-assistant, -engineer, -explainer)
  - `oauth-google.md` — full Google Cloud Console + Open WebUI walkthrough
  - `backup-restore.md` — what's at risk, off-site strategies, encryption, test cadence
  - `troubleshooting.md` — symptom→fix table from this session
- Added hardware-aware install profile picker (commit `5e71ac3`):
  - 1) Chat only · 2) Full stack · 3) Public-facing (Linux) · 4) Custom
  - Auto-defaults based on detected RAM, GPU presence
  - Warns + asks again if operator picks a profile their hardware can't sustain
  - Each section conditional on `INSTALL_OLLAMA / INSTALL_WEBUI / INSTALL_OPENCLAW / INSTALL_PUBLIC` flags

### Day 3 (2026-04-26)

- Hardware comparison discussion: Mac mini M4 vs Jetson AGX Orin 64 GB vs Jetson AGX Thor 128 GB.
  - **Operator's leaning:** consider Jetson AGX Orin 64 GB (~$2-2.5K) as the eventual brain box, or Thor (~$3K+, just shipped) for "future-proof" frontier-model use.
  - For a family-office workload, Jetson Orin runs llama3.1:70b, gpt-oss:20b, gemma4:31b comfortably; can handle 5-10 concurrent users.
- This handoff document written.

---

## 8. Outstanding work (do these next)

In rough priority order:

1. **Set up M1 Macbook** — clone repo, run `bash bootstrap.sh`, pick "Full stack" profile. Add to tailnet. Configure operator's other devices (iMac, VPS, family Macs) to point their OpenClaw at the M1's Ollama instead of VPS Ollama.

2. **Get keys onto the 2 other computers** that SSH into the VPS. Each runs:
   ```bash
   ssh-copy-id abrownsanta@251.151.167.72.host.secureserver.net
   ```
   Then permanently disable SSH password auth on the VPS. Kill the brute-force surface entirely.

3. **Fix `readyplay-marketing` DATABASE_URL** — set the env var during build:
   ```bash
   cd /opt/readyplay-marketing
   # Add DATABASE_URL=... to a build-only env file, then:
   npm run build
   pm2 restart readyplay-marketing --update-env
   ```

4. **Set up Google OAuth in Open WebUI** for family/family-office multi-user. Walkthrough: `docs/oauth-google.md`. Whitelist `@yousirjuan.ai` domain.

5. **Rename Tailnet** (cosmetic) — Tailscale admin → "Rename tailnet" → `nivram` (or whatever). Operator decides.

6. **Schedule off-site backups** — cron `tools/backup.sh` daily, encrypt with GPG, push to S3/B2/NAS. See `docs/backup-restore.md`.

7. **Decide on hardware upgrade path** for the brain:
   - Stay with Mac mini family (cheaper, simpler)
   - Jetson AGX Orin 64 GB (best perf/$ for serious LLM work)
   - Jetson AGX Thor 128 GB (frontier models like gpt-oss:120b)

8. **Possibly re-spin the WordPress staging containers** when operator wants to review them. They're stopped but volumes/configs intact:
   ```bash
   docker start nginx-staging-efor wordpress-staging-efor   # for example
   ```

---

## 9. Operating notes / gotchas to know

- **Don't run heavy LLM inference on the VPS.** It has 7.8 GB RAM shared with ~50 other containers + PM2 apps. Use it as the public-facing front door, not the inference engine. Once M1 (or Jetson) is online, point Open WebUI's `OLLAMA_BASE_URL` at the brain box via tailnet.
- **OpenClaw is currently dormant on the iMac.** LaunchAgent loaded but gateway not started in active use (we tested it during the OOM cascade). Re-enable when M1 is the brain.
- **macOS Gatekeeper warning** on `.command` files when AirDropped/downloaded — first time, right-click → Open → Open. After that they double-click normally.
- **Tailnet MagicDNS requires `--accept-dns=true`** on each Tailscale client. We had to re-up the iMac with that flag after initially using `--accept-dns=false`.
- **Docker `-p host:port` ≠ network-firewalled.** UFW alone won't block published ports. Use `DOCKER-USER` chain with `--ctorigdstport` matching.
- **Open WebUI `OLLAMA_BASE_URL=/ollama`** (relative URL) is wrong — must be a full URL like `http://host.docker.internal:11434` or `http://100.91.70.100:11434`. Otherwise model dropdown is empty.
- **Don't put nginx basic auth in front of Open WebUI** — it breaks the post-login API calls because Bearer tokens replace the basic-auth header. Open WebUI's own login is the right gate.
- **Operator's nivram.ai is unused** — operator initially picked `nivram` for the AI subdomain, then switched to `hello.yousirjuan.ai`. The cert + nginx vhost are on yousirjuan.ai only.
- **Operator's `book@averyhandyman.com` is the Open WebUI admin email** — it's their handyman business email, used for Open WebUI signin. Could change later.
- **`abrownsanta`** is the operator's username on the VPS (Linux account). Mac account is `averygoodman`. Different.

---

## 10. Quick-reference commands

### Daily ops

```bash
# health check from this Mac
cd ~/Developer/yousirjuan && bash tools/health.sh --infer

# tail Open WebUI logs on VPS
ssh vps-godaddy "docker logs -f --tail 50 open-webui"

# tail OpenClaw gateway (this Mac)
tail -f ~/.openclaw/logs/gateway.log

# tail nginx access (VPS)
ssh vps-godaddy "sudo tail -f /var/log/nginx/access.log"

# fail2ban status
ssh vps-godaddy "sudo fail2ban-client status sshd"

# what's bound where on VPS
ssh vps-godaddy "sudo ss -tlnp | head -30"

# Tailscale mesh map
tailscale status
```

### Backup

```bash
cd ~/Developer/yousirjuan
bash tools/backup.sh                          # → ~/Documents/private-ai-backups/
bash tools/backup.sh /Volumes/USB/today.tgz   # explicit path
```

### Pull a new model on VPS (carefully — RAM-limited)

```bash
ssh vps-godaddy
# verify free RAM first
free -h
# pull a small one
ollama pull gemma2:2b
# pull a bigger one (8 GB needed, plus overhead — maybe stop a few containers first)
ollama pull llama3:8b
# Open WebUI sees them automatically
```

### Force-restart something

```bash
# Open WebUI on VPS
ssh vps-godaddy "docker restart open-webui"

# Ollama on VPS
ssh vps-godaddy "sudo systemctl restart ollama"

# OpenClaw gateway on iMac
launchctl kickstart -k "gui/$(id -u)/ai.openclaw.gateway"

# nginx on VPS
ssh vps-godaddy "sudo nginx -t && sudo systemctl reload nginx"
```

### Reboot VPS (panic option)

If SSH times out: log into https://account.godaddy.com → Servers → "Restart". All services auto-come-back via systemd.

---

## 11. The repo — what lives where

```
yousirjuan/
├── README.md                       overview + quick-start (commit it)
├── HANDOFF.md                      ← this file
├── LICENSE                         "all rights reserved, internal use"
├── .env.example                    template for DOMAIN, EMAIL, etc.
├── .gitignore                      excludes secrets, logs, backups
├── bootstrap.sh                    OS-detecting universal entrypoint
│
├── installers/
│   ├── macos.sh                    full Mac install with profile wizard
│   └── linux.sh                    full Linux install with profile wizard
│
├── vps/                            for any Linux box hosting public endpoint
│   ├── apply-vps-config.sh         orchestrator: needs DOMAIN= + EMAIL=
│   ├── nginx-vhost.conf.template   templated reverse-proxy config
│   ├── fail2ban-sshd.local         SSH brute-force jail
│   ├── ollama-systemd-override.conf bind Ollama to 0.0.0.0
│   └── iptables-public-lockdown.sh blocks sensitive ports from public NIC
│
├── tools/                          run anytime
│   ├── health.sh                   status check
│   ├── backup.sh                   tarball volume + ~/.openclaw
│   ├── restore.sh                  inverse of backup.sh
│   ├── uninstall.sh                interactive teardown
│   └── glinet-router-setup.sh      configure GL.iNet routers
│
├── command-launchers/              double-clickable .command files (macOS)
│   ├── Install Private AI.command
│   ├── Check Health.command
│   ├── Backup.command
│   ├── Restore.command
│   ├── Uninstall.command
│   └── Configure Router.command
│
├── config/
│   └── openclaw.json.template      OpenClaw config (with __HOME__ + __GENERATE__ placeholders)
│
├── docker/                         (empty; future docker-compose stack)
│
└── docs/
    ├── architecture.md
    ├── adding-models.md            (operator added gemma4:26b/31b rows)
    ├── multi-user.md
    ├── rag-and-knowledge.md
    ├── modelfile-customization.md
    ├── oauth-google.md
    ├── backup-restore.md
    └── troubleshooting.md
```

---

## 12. Three numbers to remember

- **VPS public IP:** `72.167.151.251`
- **VPS tailnet IP:** `100.91.70.100` (`vps-godaddy`)
- **iMac tailnet IP:** `100.84.107.1` (`imac-avery`)

Everything else can be looked up.
