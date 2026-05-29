---
ledgerId: LEDGER-0026
title: Add clinic-vps to the family WireGuard mesh so nephew.yousirjuan.ai/chat reaches the DGX
status: shipped
opened: 2026-05-29
closed: 2026-05-29
related-pains: []
related-tickets: [LEDGER-0018, LEDGER-0027]
triggers: [manual]
---

# LEDGER-0026 — Add clinic-vps to the family WireGuard mesh

## Ask

Operator's verbatim 2026-05-29:

> we have Wireguard - its works if we set that up

Said in response to a menu of paths for bridging the VPS at `clinic-vps` (GoDaddy, public host of `nephew.yousirjuan.ai`) to the DGX Spark at home. The chat surface at `https://nephew.yousirjuan.ai/chat` was reporting offline because the VPS tower-api couldn't reach the DGX — the SSH alias `nephew-nivram` only existed in the Mac's `~/.ssh/config`. Family already runs WireGuard; the prudent move is to join the VPS to the mesh as one more peer rather than spin up a separate tunnel.

## Outcome

Adds `clinic-vps` (10.0.0.5) as the 5th peer on the family WG mesh hosted by GL-MT6000 (AX6000 Flint 2). Reuses the existing `10.0.0.0/24` server (public key `Be87LSRYnvURzDNnnHOCWdfUC/o5tDkaxrdJmEU0iAI=`) and the existing `192.168.8.0/24` LAN route every peer already has in `AllowedIPs` — so the DGX at `192.168.8.249` is reachable from the VPS without any DGX-side WG config.

DDNS provisioned via GL.iNet's built-in service: `xr5899d.glddns.com → 97.164.202.176`.

Companion code change ships in `marvelousempire/nephew` v0.68.0: `src/hermes-bridge.js` adds `NEPHEW_HERMES_DIRECT_URL` env-var short-circuit so the VPS calls the DGX directly over WG, bypassing the SSH-tunnel path the Mac uses.

## Runbooks

- [01-vps-keypair.md](runbooks/01-vps-keypair.md) — generate VPS WG keypair on `clinic-vps`
- [02-glinet-add-peer.md](runbooks/02-glinet-add-peer.md) — add the VPS public key as a peer in the GL-MT6000's `wg0.conf` (live + persistent)
- [03-glinet-ddns.md](runbooks/03-glinet-ddns.md) — enable DDNS on the GL-MT6000 so peers off-LAN reach the WG server via a stable hostname
- [04-verizon-port-forward.md](runbooks/04-verizon-port-forward.md) — add UDP/51820 port-forward on the upstream Verizon Business Internet Gateway
- [05-vps-bring-up.md](runbooks/05-vps-bring-up.md) — install `wireguard-tools`, write `/etc/wireguard/wg0.conf`, `systemctl enable --now wg-quick@wg0`
- [06-tower-api-direct-url.md](runbooks/06-tower-api-direct-url.md) — set `NEPHEW_HERMES_DIRECT_URL` in `~/.nephew/tower.env`, restart `nephew-tower-api`

## Playbooks

- [add-wg-peer-to-glinet.sh](playbooks/add-wg-peer-to-glinet.sh) — idempotent script that ssh's to the GL-MT6000 and adds a new `[Peer]` block to `/etc/wireguard/wg0.conf` + lives-applies via `wg set`. Args: peer-name, public-key, wg-ip
- no playbook for the Verizon side because the Verizon Business Gateway admin UI is closed (no SSH, no documented API). Runbook only.
- no playbook for the GL.iNet DDNS step because GL.iNet's DDNS panel is a one-time click-through with a UUID hostname assigned by their backend.

## Replay (zero-AI)

To add a NEW remote host to the mesh (using this as a template):

```bash
bash ledger/LEDGER-0026-vps-into-wg-mesh/playbooks/add-wg-peer-to-glinet.sh \
  --name <peer-name> \
  --pubkey <peer-public-key> \
  --wg-ip 10.0.0.X
```

## Verification

```bash
# From clinic-vps:
sudo wg show wg0                          # expect: handshake with Be87LSR..., bytes received > 0
ping -c 3 192.168.8.249                   # expect: DGX reachable
curl -s http://192.168.8.249:8642/v1/models | jq '.data[].id' | grep qwen2.5

# Operator-visible:
curl -s https://nephew.yousirjuan.ai/api/agents/nephew-chat/status | jq
# expect: { "ok": true, "container": "up", "api": "connected", "models": [...], "tunnel": "direct-url" }
```

HealthPill at `https://nephew.yousirjuan.ai/chat` should show green (currently red — pending Verizon port-forward resolution).

## Undo

```bash
# On VPS:
sudo systemctl disable --now wg-quick@wg0
sudo rm /etc/wireguard/wg0.conf /etc/wireguard/clinic-vps_*.key
# remove NEPHEW_HERMES_DIRECT_URL from ~/.nephew/tower.env

# On GL-MT6000:
ssh root@192.168.8.1
wg set wg0 peer 57VEld4KHjzGLuKa+jx3yBzQMhy4whePxWGZDa1gQwQ= remove
# edit /etc/wireguard/wg0.conf, remove the clinic-vps [Peer] block

# On Verizon admin (https://192.168.0.1):
# Delete the "WireGuard" port-forward rule.
```

## Status — SHIPPED 2026-05-29

All 6 phases complete. End-to-end chat at `https://nephew.yousirjuan.ai/chat` works.

### What actually shipped (the full path resolved)

| # | Layer | Resolution |
|---|---|---|
| 1 | VPS keypair | Generated on `clinic-vps`, private stays on VPS |
| 2 | GL-MT6000 peer | `clinic-vps` at `10.0.0.5/32` in live `wg show wg0` AND persisted to `/etc/wireguard/wg0.conf` |
| 3 | DDNS | `xr5899d.glddns.com` → `97.164.202.176` (live) |
| 4 | Verizon port-forward | UDP/51820 → `192.168.0.157:51820` rule confirmed working via tcpdump on GL-MT6000 |
| 5 | GL-MT6000 OpenWRT firewall | Added rule `Allow-WireGuard-VPS` (UDP/51820 INPUT) + attached `wg0` to lan zone in UCI + explicit FORWARD rules `wg0 → 192.168.8.0/24` and reverse |
| 6 | DGX networking | Cable moved from AX1800 (downstream AP) to AX6000 LAN port directly. Eliminated AP client isolation issue. Both wired (enP7s7/.249) + wifi (wlP9s9/.114) UP, but only wired carries traffic |
| 7 | DGX hermes | Rebuilt docker-compose: `127.0.0.1:8642:8642` → `8642:8642`. DGX iptables INPUT restricted tcp/8642 to `127.0.0.0/8 + 192.168.8.0/24 + 10.0.0.0/24`, DROP else. iptables-persistent installed |
| 8 | DGX sysctl | `arp_filter=1` on all interfaces + `rp_filter=2` (loose) persisted to `/etc/sysctl.d/99-nephew-arp-filter.conf` |
| 9 | hermes stale lock | Removed `/home/abrownsanta/.hermes/gateway.lock` (caused container crash-loop after recreation). Container came up clean |
| 10 | VPS tower-api | Drop-in `~/.config/systemd/user/nephew-tower-api.service.d/direct-url.conf` sets `NEPHEW_HERMES_DIRECT_URL=http://192.168.8.249:8642/v1/chat/completions` |
| 11 | VPS nginx | New `location ~ ^/api/agents/ { proxy_pass http://127.0.0.1:8088; ... }` block added BEFORE the `/api/` catch-all. SSE-friendly buffering off |
| 12 | Persistence | All firewall rules written to `/etc/firewall.user` on GL-MT6000 so they survive reboot |

### Working steady-state verification

```
curl -s https://nephew.yousirjuan.ai/api/agents/nephew-chat/status
→ {"ok":true,"container":"up","api":"connected","models":["hermes-agent"],"tunnel":"direct-url","dgx":"192.168.8.249:8642"}
```

Browser at `https://nephew.yousirjuan.ai/chat` — HealthPill green, tokens stream from family DGX.

### The unexpected gotchas (so future-us doesn't relearn them)

1. **Verizon Business Internet is NOT CGNAT** for this account (real public IP). Port-forward worked once OpenWRT firewall let it in.
2. **OpenWRT firewall blocks inbound UDP/51820 by default** even with a Verizon port-forward — need an explicit `Allow-WireGuard-VPS` rule.
3. **OpenWRT's wg0 interface is unclassified by default** — need to attach to the `lan` zone via UCI for forwarding to work.
4. **Cross-zone forwarding from wg0 → lan isn't automatic** — added explicit `iptables -I FORWARD 1 -i wg0 -d 192.168.8.0/24 -j ACCEPT` and reverse.
5. **DGX plugged into AX1800 (downstream AP) caused L2 isolation** — AX1800 didn't pass inbound LAN traffic back to its LAN clients. Moving cable directly to AX6000 LAN port fixed it.
6. **DGX dual-interface bug** (wired + wifi both on 192.168.8.0/24) — fixed with `arp_filter=1` keeping both interfaces UP.
7. **Docker port binding change forces container recreate** which left a stale `gateway.lock` causing hermes to crash-loop until manually cleared.
8. **iptables rules on the GL-MT6000 are NOT persistent** by default — write to `/etc/firewall.user` (auto-runs after every `fw3 restart`).

The full re-deployable form is captured in LEDGER-0027 (seed-to-tree).
