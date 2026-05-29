---
ledgerId: LEDGER-0026
title: Add clinic-vps to the family WireGuard mesh so nephew.yousirjuan.ai/chat reaches the DGX
status: in-progress
opened: 2026-05-29
closed: null
related-pains: []
related-tickets: [LEDGER-0018]
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

## Status note (2026-05-29)

Phases 1–5 of the runbook complete:
- VPS keypair generated
- GL-MT6000 has `clinic-vps` peer at `10.0.0.5/32` in both running interface and `/etc/wireguard/wg0.conf`
- DDNS `xr5899d.glddns.com` live, resolves to `97.164.202.176`
- VPS `/etc/wireguard/wg0.conf` written, `wg-quick@wg0` started, peer config correct
- Verizon port-forward rule added (UDP/51820 → 192.168.0.157:51820)

Phase 6 BLOCKED: WG handshake not completing despite Verizon rule appearing correct in the admin UI. VPS sends ~33 KiB of handshake attempts; GL-MT6000 receives 0 bytes back. Suspect either (a) Verizon SPI firewall dropping inbound UDP despite the port-forward, or (b) Verizon 5G Business Internet using CGNAT (would mean `97.164.202.176` is shared across customers and inbound is fundamentally impossible without an upgrade or static-IP add-on).

Diagnosis steps captured in runbook 04. Will close this ledger when handshake completes and HealthPill is green.
