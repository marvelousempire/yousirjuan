# WireGuard VPN — AX6000 Server + 3 Clients

## Status: ACTIVE

Server running on GL.iNet AX6000 (Flint 2) at `192.168.8.1`.
WireGuard interface `wg0` on `10.0.0.1/24`, port `51820`.

## Topology

```
AX6000 (home, WireGuard server)
  wg0: 10.0.0.1/24, port 51820
  LAN: 192.168.8.0/24
  WAN: 192.168.0.157 (behind Inseego FX3100)
  │
  ├── 10.0.0.2  MacBook Pro (client)
  ├── 10.0.0.3  iPhone (client)
  └── 10.0.0.4  AX1800 travel router (site-to-site client)
```

## What VPN peers can reach

- `10.0.0.0/24` — other VPN peers
- `192.168.8.0/24` — entire home LAN (DGX Spark, Mac mini, iMac, IoT)
- Specific services:
  - `192.168.8.249:5174` — DGX Spark Control Tower
  - `192.168.8.249:8000` — Bishop BFF
  - `192.168.8.249:11434` — Ollama API
  - `192.168.8.1` — Router admin + DNS

## Client configs

Saved at `~/.wireguard/` on the Mac:
- `macbook-nephew.conf` — import into WireGuard macOS app
- `iphone-nephew.conf` — AirDrop to iPhone, open in WireGuard iOS app
- `ax1800-nephew.conf` — upload to AX1800 admin → VPN → WireGuard Client

## Port forwarding required

The AX6000 WAN IP is `192.168.0.157` (behind the Inseego FX3100).
For remote access (outside the home network), forward UDP port `51820`
on the Inseego to `192.168.0.157`.

Without this, WireGuard only works from the same network as the AX6000
(which is still useful for the IPv4 routing fix — see below).

## Why we set this up

The DGX Spark has two network interfaces (wired + Wi-Fi) on the same
subnet (192.168.8.0/24), causing asymmetric routing. IPv4 connections
from the Mac to the Spark time out. SSH works because it uses IPv6.

WireGuard creates a clean new interface (wg0) with its own routing
table, bypassing the dual-interface issue entirely.

## AX1800 as travel router

When traveling: plug in the AX1800, connect it to hotel Wi-Fi.
The AX1800 auto-tunnels to the AX6000. Any device on the AX1800's
Wi-Fi gets full home LAN access — including the DGX Spark, Ollama,
Observatory, everything. No per-device VPN install needed.

## Security

- WireGuard uses Curve25519, ChaCha20, Poly1305, BLAKE2s
- All traffic between peers is encrypted
- Private keys stored in `/etc/wireguard/` on the AX6000 (root only)
- Client private keys in `~/.wireguard/` (chmod 600)
- No HTTPS needed inside the tunnel — the tunnel IS the encryption
