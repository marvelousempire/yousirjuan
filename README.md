# You-Sir Juan — Private AI Stack

Self-hosted AI infrastructure for the Marvelous Empire family office.
**Your data, your models, your infrastructure** — nothing leaves your machines.

## What this is

A reproducible deployment of:

- **[Ollama](https://ollama.com/)** — runs LLMs locally (Llama 3, Qwen 3, GPT-OSS, Gemma, etc.)
- **[Open WebUI](https://github.com/open-webui/open-webui)** — ChatGPT-style multi-user web app
- **[OpenClaw](https://openclaw.ai)** — personal AI agent with messaging-platform integrations (optional, GPU recommended)
- **[Tailscale](https://tailscale.com)** — encrypted private mesh between all your devices
- **nginx + Let's Encrypt** — public HTTPS endpoint with auto-renewing certs (when needed)
- **fail2ban + iptables** — defense-in-depth firewall
- **Caddy / Traefik** alternatives for the reverse proxy (optional, see `docker/`)

Deployable on macOS or Linux from a single bootstrap script. Idempotent — safe to re-run.

## Install profiles (the wizard picks for you)

The installer detects your hardware and recommends a profile, but you can override:

| Profile | What you get | Recommended for |
|---|---|---|
| **1 — Chat only** | Ollama + Open WebUI | Any machine — even CPU-only / low-RAM. Fast, stable. |
| **2 — Full stack** | above + OpenClaw agent | Apple Silicon Mac OR Linux box with NVIDIA GPU + 16+ GB RAM |
| **3 — Public-facing** *(Linux only)* | above + nginx + Let's Encrypt + iptables lockdown | A VPS with a public IP and a DNS A record you control |
| **4 — Custom** | Pick each component | Power users |

The wizard will **warn** if you pick a profile your hardware can't sustain (e.g. OpenClaw on Intel/CPU = unstable). You can override with eyes open.

## Quick start

### macOS (laptops, family Macs)

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
bash bootstrap.sh
```

Or **double-click** `command-launchers/Install Private AI.command` if you cloned with a GUI git client. (First time, **right-click → Open** to bypass macOS Gatekeeper.)

### Linux (the VPS, home server, family-office workstation)

```bash
git clone https://github.com/marvelousempire/yousirjuan.git
cd yousirjuan
bash bootstrap.sh
```

Tested on Ubuntu 22.04 + 24.04 + Debian 12.

### VPS public-endpoint setup (separate, after the install above)

```bash
sudo DOMAIN=hello.yousirjuan.ai EMAIL=hello@yousirjuan.ai \
  bash vps/apply-vps-config.sh
```

This stands up nginx + Let's Encrypt + fail2ban + iptables lockdown. Pre-condition: a DNS A record for `hello.yousirjuan.ai` already points at this VPS's public IP.

## Repository layout

```
yousirjuan/
├── README.md                       this file
├── LICENSE                         all rights reserved (internal use)
├── .env.example                    copy to .env, fill in secrets
├── .gitignore                      excludes secrets, logs, backups
│
├── bootstrap.sh                    universal entrypoint — detects OS, dispatches
│
├── installers/
│   ├── macos.sh                    full macOS install with wizard
│   └── linux.sh                    full Linux install (Ubuntu/Debian)
│
├── vps/                            for any Linux box that hosts the public endpoint
│   ├── apply-vps-config.sh         orchestrator: nginx + cert + fail2ban + iptables
│   ├── nginx-vhost.conf.template   reverse-proxy config (templated for any domain)
│   ├── fail2ban-sshd.local         SSH brute-force jail
│   ├── ollama-systemd-override.conf bind Ollama to 0.0.0.0
│   └── iptables-public-lockdown.sh blocks sensitive ports from public NIC
│
├── tools/                          run anytime
│   ├── health.sh                   status check (Ollama, Docker, Open WebUI, OpenClaw)
│   ├── backup.sh                   tarball of OpenWebUI volume + OpenClaw config
│   ├── restore.sh                  inverse of backup.sh
│   ├── uninstall.sh                interactive teardown
│   └── glinet-router-setup.sh      configure GL.iNet routers (Flint 2, Slate AX, etc.)
│
├── command-launchers/              double-clickable .command files for macOS Finder
│   ├── Install Private AI.command
│   ├── Check Health.command
│   ├── Backup.command
│   ├── Restore.command
│   ├── Uninstall.command
│   └── Configure Router.command
│
├── config/
│   └── openclaw.json.template      OpenClaw config — substituted at install time
│
├── docker/                         (future) docker-compose stack
│
└── docs/
    ├── architecture.md             how the pieces fit together
    ├── adding-models.md            ollama pull etc., privacy notes
    ├── multi-user.md               adding family members + family-office colleagues
    ├── rag-and-knowledge.md        upload PDFs, attach to a model
    ├── modelfile-customization.md  custom system prompts, temperatures, contexts
    ├── oauth-google.md             "Sign in with Google" setup
    ├── backup-restore.md           backup + restore walkthrough
    └── troubleshooting.md          common issues + fixes
```

## What you get out of the box

| Capability | Status |
|---|---|
| Local LLM inference (Ollama) | ✅ Multiple models, GPU-accelerated on Apple Silicon |
| ChatGPT-style web UI (Open WebUI) | ✅ Multi-user, polished |
| Per-user chat history | ✅ Each user's chats are isolated |
| Per-user uploaded knowledge (RAG) | ✅ Upload PDFs / docs, attach to chats |
| Custom system prompts per model | ✅ Workspace → Models in Open WebUI |
| Cloud model fallback (OpenAI / Claude) | ✅ Add API keys in Settings → Connections |
| Public HTTPS endpoint with TLS | ✅ via nginx + Let's Encrypt |
| Encrypted private mesh (Tailscale) | ✅ Reach your AI from any device |
| SSH brute-force protection | ✅ fail2ban |
| Public-internet attack-surface lockdown | ✅ iptables INPUT + DOCKER-USER chains |
| Voice / WhatsApp / iMessage agent (OpenClaw) | ✅ Optional, requires capable hardware |
| Backup + restore | ✅ tarball script |
| Auto-start on reboot | ✅ launchd (macOS) / systemd (Linux) |

## Security posture

This is **internal infrastructure**, not a public SaaS. Defaults assume:

- A small set of known users (family + family office)
- Devices on a trusted Tailscale mesh
- Public surface limited to one nginx vhost on 80/443

What's hardened:

- SSH key-only auth (after you add keys for all your devices)
- fail2ban bans brute-force IPs after 5 failures for 24h
- Docker port publishing is firewalled at iptables (UFW alone isn't enough)
- Open WebUI signups are disabled after admin claims account
- WEBUI_SECRET_KEY rotated to 64-char hex
- HTTPS-only public endpoint (HTTP → 301)
- HSTS + X-Content-Type-Options + X-Frame-Options headers
- MySQL / Postgres / Redis / Ollama API bound to loopback (or tailnet)
- Non-default ports (3000, 11434, 8081–8113, etc.) blocked from public NIC

What's NOT yet hardened (roadmap):

- Encrypted-at-rest disk (LUKS)
- Audit logs (who did what when)
- Off-site automated backup
- Multi-tenant isolation (separate Open WebUI instances per family)
- HSM-backed secrets

## Privacy

| Data | Stays on... |
|---|---|
| Conversations, prompts, uploads | Your VPS / Mac — Docker volume on disk |
| Local model inference | Your machine — never sent anywhere |
| Tailscale tunnel between devices | Encrypted point-to-point (WireGuard); even Tailscale Inc. cannot decrypt |
| HTTPS cert | Issued by Let's Encrypt — they know your domain exists, see zero data |
| Model downloads from ollama.com | Their CDN sees you downloaded model X (one time per model) |
| Cloud-API conversations (if you add OpenAI/Claude keys) | Sent to that provider — only when YOU explicitly route to that model |

## Models

Run `ollama list` anytime to see installed models. Add more:

```bash
ollama pull qwen3:14b
ollama pull gpt-oss:20b
ollama pull llama3:8b
```

See `docs/adding-models.md` for the catalog at https://ollama.com/library and recommendations by RAM.

## Development / iteration

This repo is the source of truth. Changes flow:

```
edit on your laptop → git commit → git push → ssh into VPS / Mac → git pull → re-run bootstrap.sh
```

Every script is idempotent — re-running is safe.

## Contributing (you, future-you, and family-office hires)

```bash
git checkout -b feature/<name>
# edit
git commit -m "..."
git push -u origin feature/<name>
gh pr create
```

## License

Internal use only. See `LICENSE`.
