# Architecture

How the You-Sir Juan stack fits together.

## The 30-second view

```
                  ┌────────────────────────────────────────────────────┐
                  │            Public internet (HTTPS only)            │
                  └────────────────────┬───────────────────────────────┘
                                       │
                            DNS  hello.yousirjuan.ai
                                       │
                                       ▼
                  ┌────────────────────────────────────────────────────┐
                  │   VPS  (Ubuntu 24.04, 7.8 GB RAM, 4 GB swap)       │
                  │                                                    │
                  │   nginx :443 ──┐  Caddy :8443 (other use)          │
                  │   Let's Encrypt│                                   │
                  │                ▼                                   │
                  │     reverse proxy                                  │
                  │                │                                   │
                  │                ▼                                   │
                  │   Open WebUI (Docker, :3000 loopback)              │
                  │                │                                   │
                  │                ▼                                   │
                  │   Ollama  :11434  (model: llama3.2:latest)         │
                  │                                                    │
                  │   fail2ban  +  iptables INPUT  +  DOCKER-USER      │
                  │   tailscale0   (private mesh interface)            │
                  └────────────────────┬───────────────────────────────┘
                                       │ encrypted Tailscale mesh
                                       │ (WireGuard underneath)
              ┌────────────────────────┼────────────────────────┐
              │                        │                        │
       ┌──────▼──────┐         ┌───────▼──────┐         ┌───────▼──────┐
       │  iMac       │         │  M1 Macbook  │         │  iPhone      │
       │  Open WebUI │         │  Ollama (M1  │         │  Tailscale   │
       │  client     │         │  Metal GPU)  │         │  + Safari    │
       │  OpenClaw   │         │  OpenClaw    │         │  to hello.   │
       │  (body)     │         │  (body)      │         │  yousirjuan  │
       └─────────────┘         └──────────────┘         └──────────────┘
```

## Layers

### 1. Public DNS + TLS (nginx + Let's Encrypt)
- DNS A record: `hello.yousirjuan.ai → 72.167.151.251`
- nginx vhost terminates TLS, reverse-proxies to Open WebUI on `127.0.0.1:3000`
- Certbot auto-renews the Let's Encrypt cert
- HTTP → 301 → HTTPS (no plaintext public)

### 2. App layer (Open WebUI)
- Docker container `open-webui`, port `3000` (publicly blocked by `iptables INPUT` rule on the public NIC; reachable via tailnet AND through nginx reverse proxy on `:443`)
- SQLite DB at `/app/backend/data/webui.db` (volume `open-webui` on host disk)
- Uses Ollama at `http://host.docker.internal:11434` for inference

### 3. Inference layer (Ollama)
- Native install (Linux package — no Docker, no GPU virtualization issues)
- Bound to `0.0.0.0:11434` (so containers can reach via `host.docker.internal`)
- `OLLAMA_KEEP_ALIVE=5m` — releases idle models to free RAM
- `OLLAMA_MAX_LOADED_MODELS=1` — never load multiple at once (RAM-constrained)
- Models stored at `/home/$USER/.ollama/models` (configurable)

### 4. Agent layer (OpenClaw — optional, runs on each device)
- npm-installed; gateway runs as systemd unit (Linux) or LaunchAgent (macOS)
- Calls out to whichever Ollama is configured (local or remote via tailnet)
- "Body" plugins (browser control, file ops, voice, etc.) execute locally
- "Brain" calls (LLM inference) go to whatever Ollama URL is in `models.providers.ollama.baseUrl`

### 5. Network layer (Tailscale)
- Each device runs the Tailscale client → joins the same tailnet
- Each device gets a `100.x.x.x` IP that's reachable over WireGuard from any other device
- MagicDNS gives every device a friendly hostname (`vps-godaddy`, `imac-avery`, etc.)
- The tailnet bypasses NAT, public firewalls, hotel wifi blocks — works anywhere

### 6. Public-port lockdown (iptables)
- **INPUT chain**: drops public-NIC traffic to host services (Ollama, Nydus, etc.)
- **DOCKER-USER chain**: drops public-NIC traffic to Docker-published ports using `--ctorigdstport` (because Docker DNATs the port before FORWARD chain sees it — `--dport` would never match)
- Tailscale interface `tailscale0` is left alone — devices on the mesh have full access
- Persisted via `iptables-persistent` so rules survive reboots

### 7. SSH protection (fail2ban)
- 5 failed SSH attempts in 10 min → 24-hour ban
- Mitigates the ~2,700 daily brute-force attempts the public IP attracts

## Data flow examples

### Family member chats from their laptop (on cellular):
```
laptop → public internet → DNS → nginx :443 (TLS) → Open WebUI :3000
       → Open WebUI auth check → user's chat session
       → Open WebUI calls Ollama → llama3.2:latest generates response
       → response back through nginx → laptop
```

### iPhone uses OpenClaw via tailnet:
```
iPhone (Tailscale on) → tailnet → vps-godaddy:11434 (Ollama)
                                → response → OpenClaw on iPhone
                                → OpenClaw executes local action (Shortcut, etc.)
```

### M1 Mac is the brain instead:
```
Other devices' OpenClaw → tailnet → m1-mac:11434 (Ollama with Metal GPU)
                                  → ~30-50 tok/s vs ~3-8 on VPS CPU
```

## Why this layout

- **Self-hosted = no third-party reads your data.** Conversations + models + uploads stay on your hardware.
- **Public endpoint = accessible from any device** without making everyone install Tailscale (use case: family member at the doctor's office wants to look something up).
- **Tailnet endpoint = trusted-device shortcuts** for power use (no nginx, no public TLS, faster).
- **iptables + fail2ban + Docker port lockdown** = the public attack surface is just `22, 80, 443` despite many services running.
- **Swap + Ollama memory hygiene** = small VPS doesn't OOM under load.
- **Repo as source of truth** = re-deploy anywhere by `git clone + bootstrap.sh + apply-vps-config.sh`.
