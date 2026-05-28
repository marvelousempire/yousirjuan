# Network Architecture — Segmented + Secure

## Hardware Inventory

| Device | Model | Role |
|---|---|---|
| **GL.iNet AX6000** (Flint 2) | GL-MT6000 | Primary router, WireGuard server, VLANs, firewall |
| **GL.iNet AX1800** (Flint) | GL-AX1800 | IoT Wi-Fi AP (bridge to VLAN 20) |
| **Verizon 5G Business Internet Gateway (6-antenna)** | Verizon 5G Business Internet | WAN gateway (modem only — AX6000 routes behind it) |
| **Apple Airport Extreme ×2** | A1521 | Bridge-mode Wi-Fi APs for coverage |
| **Netgear WN3500RP** | Wi-Fi extender | **RETIRED** — no VLAN, no security updates |

## Topology — 3 Isolated VLANs

```
Internet (ISP / Verizon 5G Business Internet Gateway (6-antenna) 5G)
  │
  ▼
┌──────────────────────────────────────────────────────────────┐
│  GL.iNet AX6000 — PRIMARY ROUTER                            │
│  WireGuard SERVER · VLANs · Firewall                        │
│                                                              │
│  VLAN 10 — AI / Compute (TRUSTED)                           │
│  ├── DGX Spark (wired ethernet, 2.5 Gbps)                  │
│  ├── MacBook Pro M5 Max (Wi-Fi 6 or wired)                 │
│  ├── Mac mini M4 Max (wired)                                │
│  ├── iPhone / iPad (Wi-Fi)                                  │
│  ├── iMac 2017 (wired)                                      │
│  └── WireGuard peers (remote access)                        │
│  SSID: "Nephew-AI" (WPA3)                                   │
│                                                              │
│  VLAN 20 — IoT / Smart Home (ISOLATED)                      │
│  ├── Smart bulbs, cameras, thermostats, speakers            │
│  ├── HomeKit hub                                             │
│  └── GL.iNet AX1800 as dedicated AP                         │
│  SSID: "Home-IoT" (WPA2, separate password)                 │
│  Firewall: VLAN 20 → VLAN 10 = DROP                        │
│                                                              │
│  VLAN 30 — Guest (QUARANTINED)                              │
│  ├── Visitors                                                │
│  └── Untrusted devices                                       │
│  SSID: "Guest"                                               │
│  Firewall: No LAN access, internet only                     │
└──────────────────────────────────────────────────────────────┘
```

## Device Placement

| Device | VLAN | Connection | Notes |
|---|---|---|---|
| DGX Spark | 10 | Wired to AX6000 | 2.5G ethernet, never Wi-Fi |
| MacBook Pro | 10 | Wi-Fi or wired | Primary dev machine |
| Mac mini | 10 | Wired to AX6000 | Always-on orchestration |
| iMac 2017 | 10 | Wired | Backend server, light inference |
| iPhone/iPad | 10 | Wi-Fi (Nephew-AI SSID) | Mobile access |
| IoT devices | 20 | Wi-Fi (Home-IoT SSID) | Completely isolated |
| Airport Extreme #1 | 10 | Bridge, wired backhaul | Extra coverage for AI/Work |
| Airport Extreme #2 | 20 | Bridge, wired backhaul | Extra coverage for IoT |
| AX1800 | 20 | Bridge/AP, wired to AX6000 | Dedicated IoT radio |

## Firewall Rules

| From | To | Action | Why |
|---|---|---|---|
| VLAN 20 (IoT) | VLAN 10 (AI) | **DROP** | Compromised IoT can't reach Spark/Mac |
| VLAN 30 (Guest) | VLAN 10 (AI) | **DROP** | Guests can't see anything |
| VLAN 30 (Guest) | VLAN 20 (IoT) | **DROP** | Guests can't control smart home |
| VLAN 10 (AI) | VLAN 20 (IoT) | **ACCEPT** | You CAN control IoT from your Mac |
| All VLANs | WAN | **ACCEPT** | Everyone gets internet |

## WireGuard Remote Access

The AX6000 runs a WireGuard server. Client configs generated for:
- MacBook Pro (for travel / coffee shop / co-working)
- iPhone (for mobile access away from home)

Peers land on VLAN 10 — same access as being at home on the AI network.

### Setup steps (AX6000 admin panel)

1. `http://192.168.8.1` → VPN → WireGuard Server → Enable
2. Port: 51820 (forward on Verizon Business Gateway if it's the WAN gateway)
3. Generate client configs → download .conf for Mac, scan QR for iPhone
4. AllowedIPs: `10.0.0.0/24, 192.168.8.0/24`

## Why Not Tailscale

The GL.iNet routers have WireGuard built into the firmware. Benefits over Tailscale:
- No third-party coordination server
- Hardware-accelerated on AX6000
- No per-device install needed
- Full self-hosted full ownership

## Retired Hardware

- **Netgear WN3500RP** — old, no VLAN support, no security updates. Do not use.
- **Jetson Thor** — NOT YET PURCHASED. When acquired, it will join VLAN 10 as an edge inference node alongside the DGX Spark.

---

## IPv4 vs IPv6 — The Dual-Interface Issue (Resolved)

### Problem
The DGX Spark has two network interfaces on the same subnet:
- `enP7s7` (wired) — `192.168.8.249`
- `wlP9s9` (Wi-Fi) — `192.168.8.114`

Both on `192.168.8.0/24`. This causes **asymmetric routing** — packets arrive on one interface but replies go out the other. The AX6000 router drops them. Result: IPv4 connections from the Mac to the Spark time out on every port. SSH works because it resolves via **IPv6** (`fd4b:36c7:d004::ffe`) which doesn't have the dual-interface issue.

### Solution
1. **Bind services to `::` (all interfaces, IPv4 + IPv6)** instead of `0.0.0.0` (IPv4 only)
2. **Access the Spark via IPv6** using the hostname alias `nephew-spark`
3. **WireGuard VPN** for remote access (when away from home, the VPN creates a clean routing path)

### Hostname alias
Added to `/etc/hosts` on the Mac:
```
fd4b:36c7:d004::ffe nephew-spark
```
Access: `http://nephew-spark:5174` — resolves to IPv6, bypasses the IPv4 routing issue.

### Vite allowedHosts
The Spark's Vite config (`apps/control-tower/vite.config.ts`) includes:
```js
server: {
  allowedHosts: ["nephew-spark", "nephew-nivram", ".localhost"],
}
```
Without this, Vite blocks requests from non-localhost hostnames.

### Access matrix

| Location | How to access Spark CT | Protocol |
|---|---|---|
| At home (LAN) | `http://nephew-spark:5174` | IPv6 direct |
| At home (SSH) | `ssh nephew-nivram` | IPv6 (auto) |
| Away (WireGuard on) | `http://nephew-spark:5174` | IPv6 via VPN |
| Away (no VPN) | SSH tunnel: `ssh -L 5174:localhost:5174 nephew-nivram` | IPv6 SSH |

### What we tried that didn't work (for the record)
- **UFW on the Spark** — enabled with port allows, didn't help (IPv4 routing was the issue, not firewall)
- **nft flush ruleset** — cleared all NVIDIA nftables rules, still timed out
- **Disabling Wi-Fi on the Spark** — killed SSH (SSH was using IPv6 over Wi-Fi). Had to reboot to recover.
- **AP isolation on AX6000** — was already off on main radios
- **WireGuard from the same LAN** — Mac's local route to `192.168.8.0/24` takes priority over VPN route, so VPN can't override the broken IPv4 path when already on the same subnet

### What works
- **IPv6 is the production path** for LAN access
- **WireGuard is the production path** for remote access
- **IPv4 to the Spark is broken** due to dual-interface routing — don't fight it, use IPv6
