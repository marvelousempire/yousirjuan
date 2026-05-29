---
ledgerId: LEDGER-0027
title: Seed-to-Tree — full re-deployable Nephew family AI infrastructure
status: shipped
opened: 2026-05-29
closed: 2026-05-29
related-pains: []
related-tickets: [LEDGER-0026, LEDGER-0018]
triggers: [manual, disaster-recovery]
---

# LEDGER-0027 — Seed-to-Tree

## Ask

Operator's verbatim 2026-05-29:

> explain our full setup and the instant install and setup files to replace the system from seed to tree - give it all a log in yousirjuan

After the chat surface went live at `https://nephew.yousirjuan.ai/chat` through a 12-hop family WireGuard mesh, the operator wants the full bootstrap captured so the entire stack can be re-deployed from bare metal in a known-good way — by Avery, by any family member who joins later, by a future agent.

## Outcome

This ledger captures **every node in the family AI stack** and the exact path from bare metal to a working `nephew.yousirjuan.ai/chat` HealthPill-green deployment:

- 9 atomic runbooks (one per layer of the stack)
- 4 idempotent playbooks (the work that can be scripted)
- 6 artifact templates (configs the playbooks render)
- A single replay command per node

Any node can be rebuilt in under an hour from these artifacts.

## The system at a glance

```
┌──────────────────────────────────────────────────────────────────────────┐
│  Public surface — nephew.yousirjuan.ai                                  │
│  └─ nginx /api/agents/* → tower-api → WG → DGX                          │
└──────────────────────────────────────────────────────────────────────────┘
                ↑
                │  HTTPS (Let's Encrypt)
                │
        clinic-vps (GoDaddy, Ubuntu)
        ├─ nginx (TLS termination, /api routes)
        ├─ nephew-tower-api systemd user service :8088
        ├─ Bishop :8000 (auth/OIDC)
        └─ wg-quick@wg0 (10.0.0.5/24)
                ↑
                │  WG UDP/51820 (encrypted)
                │  Endpoint: xr5899d.glddns.com:51820
                ↓
        Verizon Business Internet Gateway (97.164.202.176)
        └─ Port-forward 51820/udp → 192.168.0.157
                ↓
        GL-MT6000 (GL.iNet Flint 2 / "AX6000") — 192.168.0.157 WAN / 192.168.8.1 LAN
        ├─ WireGuard server (10.0.0.0/24)
        │   ├─ MacBook Pro    10.0.0.2
        │   ├─ iPhone         10.0.0.3
        │   ├─ GL-AX1800      10.0.0.4
        │   └─ clinic-vps     10.0.0.5
        ├─ DDNS xr5899d.glddns.com → Verizon WAN
        ├─ OpenWRT firewall: Allow-WireGuard-VPS + wg0 in lan zone + FORWARD rules
        ├─ /etc/firewall.user (persists rules across reboot)
        └─ DHCP server for 192.168.8.0/24
                ↓
        DGX Spark (Ubuntu 24.04 arm64) — direct cable to AX6000 LAN port
        ├─ enP7s7 192.168.8.249/24 (wired — primary)
        ├─ wlP9s9 192.168.8.114/24 (wifi — secondary, kept UP)
        ├─ /etc/sysctl.d/99-nephew-arp-filter.conf (arp_filter=1, rp_filter=2)
        ├─ iptables INPUT: tcp/8642 ACCEPT from 127/8 + 192.168.8/24 + 10.0.0/24, DROP else
        ├─ iptables-persistent
        ├─ Docker rootful
        ├─ Hermes container :8642 (binds 0.0.0.0:8642)
        │   ├─ ~/.hermes/docker-compose.yml
        │   ├─ HERMES_UID=1000, HERMES_GID=1000
        │   └─ Bind mount: ~/.hermes → /opt/data
        └─ Ollama on host :11434 (qwen2.5:32b, others)
                ↑
                │  Mac SSH tunnel (for local CLI / iMessage path)
                │  ssh -fNL 8642:127.0.0.1:8642 nephew-nivram
                ↓
        MacBook Pro (Operator dev surface)
        ├─ ~/Developer/{nephew, yousirjuan, ...}
        ├─ ~/.wireguard/macbook-nephew.conf
        ├─ ~/.ssh/config: nephew-nivram → IPv6 alias
        └─ ~/.nephew/tower.env (NEPHEW_HERMES_KEY, etc.)
```

## Runbooks

Each runbook is atomic — one phase, ≤ 5 min to read, replayable on its own. Numbered by the order you'd execute on a fresh stack.

- [`01-hardware-inventory.md`](runbooks/01-hardware-inventory.md) — physical bill of materials
- [`02-vps-provision.md`](runbooks/02-vps-provision.md) — get a fresh Ubuntu VPS at the cloud provider
- [`03-glmt6000-bootstrap.md`](runbooks/03-glmt6000-bootstrap.md) — flash GL.iNet AX6000 (Flint 2), set passwords, define LAN, enable WireGuard server, enable DDNS, set OpenWRT firewall rules + persistence
- [`04-dgx-bootstrap.md`](runbooks/04-dgx-bootstrap.md) — Ubuntu 24.04 install, Docker, Ollama, Hermes container, sysctl, iptables
- [`05-wireguard-mesh.md`](runbooks/05-wireguard-mesh.md) — add each peer to the mesh (Mac, iPhone, AX1800, VPS, future nodes). Wraps the playbook from LEDGER-0026
- [`06-verizon-port-forward.md`](runbooks/06-verizon-port-forward.md) — UDP/51820 → GL-MT6000 WAN IP on the Verizon Business Gateway
- [`07-nephew-ct-deploy.md`](runbooks/07-nephew-ct-deploy.md) — Nephew Control Tower static build + nginx routes (including `/api/agents/*` proxy + SSE-friendly buffering)
- [`08-tower-api-direct-url.md`](runbooks/08-tower-api-direct-url.md) — systemd drop-in sets `NEPHEW_HERMES_DIRECT_URL` so VPS tower-api uses the WG path instead of SSH tunnel
- [`09-verify-end-to-end.md`](runbooks/09-verify-end-to-end.md) — the smoke test chain — wg handshake → ping DGX → curl hermes → tower-api status → production endpoint

## Playbooks

- [`vps-bootstrap.sh`](playbooks/vps-bootstrap.sh) — runs on a fresh Ubuntu VPS, installs everything (wireguard-tools, nginx, Node 20, sets up tower-api systemd unit, idempotent)
- [`dgx-bootstrap.sh`](playbooks/dgx-bootstrap.sh) — runs on a fresh Ubuntu DGX Spark, installs Docker rootful + iptables-persistent + writes sysctl rules + restricts hermes 8642 to LAN+WG, idempotent
- [`glmt6000-firewall-persist.sh`](playbooks/glmt6000-firewall-persist.sh) — runs on the GL-MT6000 OpenWRT shell, writes `/etc/firewall.user` with the WG forwarding rules, idempotent
- [`verify-end-to-end.sh`](playbooks/verify-end-to-end.sh) — runs on the operator's Mac, walks the full stack: WG handshake on every node → ping DGX → curl hermes → tower-api status → production `/api/agents/nephew-chat/status` should return `ok:true`

## Artifacts (config templates)

- [`artifacts/glmt6000-firewall.user`](artifacts/glmt6000-firewall.user) — the FORWARD rules that go in `/etc/firewall.user` on the GL-MT6000
- [`artifacts/dgx-sysctl-arp-filter.conf`](artifacts/dgx-sysctl-arp-filter.conf) — `/etc/sysctl.d/99-nephew-arp-filter.conf` content
- [`artifacts/dgx-iptables-restore.rules`](artifacts/dgx-iptables-restore.rules) — INPUT rules for tcp/8642 restriction, loaded by iptables-persistent
- [`artifacts/dgx-docker-compose.yml`](artifacts/dgx-docker-compose.yml) — Hermes container config (port binding + bind mount + env)
- [`artifacts/vps-nginx-agents.conf`](artifacts/vps-nginx-agents.conf) — the nginx location block for `/api/agents/*` → tower-api with SSE support
- [`artifacts/vps-tower-api-direct-url.conf`](artifacts/vps-tower-api-direct-url.conf) — systemd drop-in for `NEPHEW_HERMES_DIRECT_URL`
- [`artifacts/wg-client-template.conf`](artifacts/wg-client-template.conf) — wg0.conf template for a new peer

## Replay (zero-AI) — bootstrap a full fresh stack

```bash
# 1. VPS (paste once on a fresh Ubuntu VPS)
curl -fsSL https://raw.githubusercontent.com/marvelousempire/yousirjuan/main/ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/vps-bootstrap.sh | sudo bash

# 2. DGX (paste once on a fresh Ubuntu DGX)
curl -fsSL https://raw.githubusercontent.com/marvelousempire/yousirjuan/main/ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/dgx-bootstrap.sh | bash

# 3. GL-MT6000 (paste once via SSH to root@192.168.8.1)
wget -qO- https://raw.githubusercontent.com/marvelousempire/yousirjuan/main/ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/glmt6000-firewall-persist.sh | sh

# 4. Verify
bash ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/verify-end-to-end.sh
```

Manual steps (router admin UI / Verizon admin / GL.iNet admin) are captured in their runbooks — those can't be scripted because the surfaces are GUI-only.

## Verification

```bash
bash ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/verify-end-to-end.sh
```

Expected end-state output:

```
[1/8] VPS WG handshake               ... ok (latest < 60s)
[2/8] VPS → DGX ping over WG         ... ok (< 200ms)
[3/8] VPS → DGX hermes /v1/models     ... ok (qwen2.5 listed)
[4/8] VPS tower-api local /status    ... ok (api:connected, tunnel:direct-url)
[5/8] nephew.yousirjuan.ai HTTPS     ... ok (200, valid cert)
[6/8] production /api/agents/.../status ... ok (api:connected)
[7/8] /chat renders                   ... ok (HTML returned)
[8/8] DGX hermes container up         ... ok

All green — family AI stack is live.
```

## Undo / disaster recovery

- **Single peer goes down** — remove from `/etc/wireguard/wg0.conf` on GL-MT6000 + remove `[Peer]` block; rest of mesh unaffected
- **GL-MT6000 dies** — reflash from this ledger's runbook 03; existing peers reconnect once DDNS resolves to new WAN IP
- **DGX dies** — reflash from runbook 04; remaining peers cannot reach hermes until new DGX is registered
- **VPS dies** — reprovision from playbook `vps-bootstrap.sh`; resync with `make deploy` from the operator's Mac

The two persistent stores are: (a) `~/.hermes/` on the DGX (model weights, gateway state) — back up to NAS; (b) `~/.nephew/` on the VPS — small, rsync-able to operator's Mac.

## Notes

- This ledger documents the system **as it actually shipped on 2026-05-29**. Future architectural shifts (Family Office NAS, additional DGX nodes, NeMo Riva voice, etc.) supersede this ledger and should land in their own LEDGER entries.
- Cross-reference: full system topology lives at `docs/hardware/network-architecture.md` in this repo.
- Plan-level companion: `nephew/plans/0090-vps-wireguard-direct-dgx.md` in the Nephew repo documents the VPS-side code change (`NEPHEW_HERMES_DIRECT_URL` short-circuit).
