---
ledgerId: LEDGER-0018
title: Tailscale → WireGuard migration plan (GL.iNet AX1800 + AX600 + VPS-anchored mesh)
status: planning
opened: 2026-05-21
closed: null
related-tickets: [LEDGER-0006, LEDGER-0008, LEDGER-0012]
triggers:
  - manual: operator decision to migrate
---

# LEDGER-0018 — Tailscale → WireGuard migration

## Ask

Operator 2026-05-21: *"How can we convert everything from Tailnet to Wireguard on our Glinet AX600 and AX1800?"*

Reduce third-party dependency on Tailscale Inc., move to fully self-controlled WireGuard mesh anchored at the VPS with the two GL.iNet routers acting as subnet gateways.

## What we lose vs gain

| Tailscale (today) | WireGuard (target) |
|---|---|
| MagicDNS — `vps-godaddy` auto-resolves | Manual: internal DNS server OR hosts file on each peer |
| Auto NAT-traversal (DERP relays) | Must port-forward UDP/51820 on at least one peer (the WG server) |
| ACLs (tag-based, JSON config in UI) | Manual `AllowedIPs` per-peer + iptables rules on the server |
| Easy install + auth (login → joined) | Per-device config file + key exchange |
| Tailscale Funnel (public HTTPS without port-forward) | Need separate solution (nginx on VPS already covers this) |
| Subscription concern: free tier limits, account control | None — fully self-hosted |
| Performance | Slightly faster (kernel-level, no userspace daemon) |
| Mobile auth flows | Manual QR-code install per phone |

**Net:** WireGuard is more work to set up and maintain, but no third-party dependency. The VPS already has a stable public IP, so the NAT-traversal loss is non-blocking — we just port-forward 51820 to it.

## Architecture decision: VPS as the WG server

| Role | Device | Why |
|---|---|---|
| **WG server** | VPS at 72.167.151.251 | Stable public IP, always-on, ubuntu 24.04 with `wg-quick` available |
| **WG client + subnet router** | AX1800 (Flint, home) | Routes ENTIRE home LAN to the tunnel — no per-device client needed |
| **WG client + subnet router** | AX600 (secondary location) | Same pattern at remote site |
| **WG client (per-device)** | iPhone, iPad, MacBook when away from home | Direct dial-in via WireGuard app |
| **No WG client needed** | iMac, Mac mini (at home) | Reach VPS via AX1800's subnet route; no client install |

Subnet routing through the GL.iNet routers means **most home devices don't need WireGuard installed at all** — they reach the VPS via the router's tunnel transparently. This is the operational equivalent of how Tailscale's "subnet routing" feature works.

## IP plan

| Network | CIDR | Purpose |
|---|---|---|
| `10.100.0.0/24` | server subnet | The WG mesh; each peer gets a /32 inside this |
| `10.100.0.1` | VPS server | gateway / DNS |
| `10.100.0.10` | AX1800 home router | subnet route → 192.168.1.0/24 |
| `10.100.0.11` | AX600 secondary router | subnet route → 192.168.2.0/24 |
| `10.100.0.20` | iMac (direct client, optional) | for when not behind AX1800 |
| `10.100.0.30+` | mobile clients (iPhone, iPad, MacBook) | per-device |

## Migration sequence (proposed phases)

### Phase 1 — Set up WG server on VPS in parallel with Tailscale (no downtime)

```bash
# On VPS, runs alongside Tailscale; uses different port (51820 vs Tailscale 41641)
sudo apt-get install wireguard
sudo wg genkey | sudo tee /etc/wireguard/server-private.key | wg pubkey | sudo tee /etc/wireguard/server-public.key
sudo bash <playbook>  # generates /etc/wireguard/wg0.conf + enables systemd unit
```

Verify by adding ONE test client (e.g. a phone). Confirm tunnel works. Tailscale stays running during this entire phase.

### Phase 2 — Add AX1800 (Flint) as a client

In GL.iNet admin UI (http://192.168.1.1):
1. VPN → WireGuard Client → New
2. Paste config provided by `<playbook> add-client --name flint`
3. Enable "Allow access to local network" (subnet routing)
4. Save + connect

Test from home LAN device: `ping 10.100.0.1` should reach the VPS over WG.

### Phase 3 — Add AX600 (secondary location) same way

### Phase 4 — Per-device mobile clients (iPhone, iPad, MacBook-when-traveling)

Generate one config per device. Each gets a QR code. Install via WireGuard app.

### Phase 5 — Stress test for a week

Run BOTH Tailscale AND WireGuard. Compare:
- Reachability (can iMac SSH to VPS via WG IP?)
- Bandwidth (`iperf3` test)
- Stability (any drops?)

### Phase 6 — Cut over

Update every yousirjuan repo's reference from `vps-godaddy` (Tailscale name) to `10.100.0.1` (WG IP) OR set up internal DNS that resolves `vps-godaddy` to the WG IP. Then disable Tailscale on each device.

### Phase 7 — Uninstall Tailscale

After 7 days of WG-only operation with no issues, uninstall Tailscale from all devices.

## What this PR ships (planning only — no migration execution)

- README (this file) — architecture + tradeoffs + sequence
- `runbooks/01-vps-wg-server-install.md` — Phase 1 step-by-step
- `runbooks/02-glinet-router-as-subnet-client.md` — Phase 2 step-by-step (GL.iNet UI screenshots in operator's TODO)
- `runbooks/03-per-device-client.md` — Phase 4 step-by-step
- `playbooks/install-wg-server.sh` — Phase 1 automation on VPS
- `playbooks/add-wg-client.sh` — generates client config + QR code for any new peer

**Operator runs `install-wg-server.sh` when ready to start Phase 1.** Nothing on the VPS changes until then.

## Critical: respect LEDGER-0014 operator-intent

Tailscale is currently a load-bearing dependency for:
- LEDGER-0006 GitLab warm-standby (Tailscale interface for the sync)
- LEDGER-0008 iMac state server (Tailscale ACL on :9876)
- LEDGER-0012 VPS agent (Tailscale ACL on :9878)
- LEDGER-0015 alert-watch (poll over Tailscale to vps-godaddy)

The migration MUST keep all of these working. Phase 6 cutover requires updating every Tailscale hostname reference + every ACL → WG `AllowedIPs` translation. Do NOT just stop Tailscale before the cutover is verified.

## Open questions (for operator)

1. Is the AX1800 firmware version recent enough for WG subnet-router mode? (Verify in admin UI → System → Firmware)
2. Does your ISP provide a static public IP for the home WAN, or dynamic? If dynamic: you'll want DDNS for the home end (or only-VPS-server model works because home only initiates outbound to VPS)
3. Phone preference: WireGuard official app, or Mullvad's open-source client?

## Cross-references

- LEDGER-0006 — Tailscale dependency (GitLab sync)
- LEDGER-0008 — Tailscale ACL pattern (will become AllowedIPs)
- LEDGER-0012 — Tailscale ACL pattern (same)
- Rule 15 (NEW in this PR) — "One Tower, One URL" — applies to UI surfaces; orthogonal to network layer but same operating philosophy (consolidate control)
