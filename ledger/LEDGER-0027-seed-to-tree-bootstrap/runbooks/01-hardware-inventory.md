# 01 — Hardware Inventory

## Why

A bare-metal bootstrap starts with the right physical bill of materials. This is what the Nephew family AI stack runs on today.

## Bill of materials

| Item | Model / spec | Role |
|---|---|---|
| ISP gateway | Verizon Business Internet Gateway (6-antenna) | WAN gateway only — DOES NOT do CGNAT for this account (verified 2026-05-29) |
| Family router | GL.iNet GL-MT6000 (Flint 2, "AX6000") | Primary LAN router, WireGuard server, OpenWRT firewall, DDNS client |
| Family AP | GL.iNet GL-AX1800 (Flint) | IoT Wi-Fi AP (bridged to GL-MT6000) — NOT used for the DGX (the DGX wires directly to GL-MT6000 LAN ports) |
| AI compute | NVIDIA DGX Spark (arm64) | Ubuntu 24.04, runs Hermes container + Ollama with qwen2.5:32b |
| Operator dev machine | MacBook Pro (M-series) | Operator code + iMessage bridge + CLI surface |
| Operator mobile | iPhone | Mobile chat surface, WireGuard client |
| VPS | GoDaddy Ubuntu (`clinic-vps`) | Public surface at `nephew.yousirjuan.ai`, nginx + tower-api + WireGuard client |

## Physical cabling that matters

1. **Verizon Business Gateway** ← (ISP fiber/cable)
2. **GL-MT6000 WAN port** ← Verizon Gateway LAN port
3. **GL-MT6000 LAN port 1** ← DGX Spark wired NIC (`enP7s7`)  
   — DGX wifi NIC (`wlP9s9`) stays UP but isn't the primary path (kept up so the IPv6 SSH alias `nephew-nivram` works)
4. **GL-MT6000 LAN port 2** ← GL-AX1800 WAN port (for IoT mesh)
5. Mac and iPhone connect via Wi-Fi to the GL-MT6000 (SSID typically `Nephew-AI`)

**Don't plug the DGX into the AX1800.** AP-mode client isolation will silently break LAN-side reachability from upstream peers — a 3-hour debug session was burned discovering this 2026-05-29.

## Success criteria

- All devices powered on
- `ping 192.168.8.1` from any LAN client returns < 5ms
- `ping 192.168.8.249` from the GL-MT6000 itself returns < 5ms (DGX wired works)
- DGX is `ssh nephew-nivram` reachable from Mac

## Undo

Power-cycle the affected device or replace with a like-for-like. Network state on the family side is in router NVRAM + DGX disk; the operator can re-image both from their respective runbooks.
