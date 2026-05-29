# 06 — Verizon Port-Forward (UDP/51820 → GL-MT6000)

## Why

The Verizon Business Internet Gateway is upstream of the GL-MT6000 and holds the public WAN IP (currently `97.164.202.176`). For off-LAN WG peers to reach the family mesh, Verizon must forward UDP/51820 inbound to the GL-MT6000's WAN-side IP (`192.168.0.157`).

## Steps (Verizon admin UI — GUI, can't be scripted)

1. Browser → `https://192.168.0.1`.
2. Log in with the admin password from the Verizon Gateway sticker (printed on the device).
3. Navigate to **Security & Firewall → Port Forwarding**.
4. **Create Rule**:
   - Application: `WireGuard`
   - Protocol: `UDP`
   - Original Port: `51820`
   - Fwd to Addr: `192.168.0.157` (the GL-MT6000's WAN-side IP)
   - Fwd to Port: `51820`
5. Apply.

## Verification

Use tcpdump on the GL-MT6000 to confirm Verizon forwards inbound UDP/51820:

```bash
ssh root@192.168.8.1
opkg update && opkg install tcpdump-mini   # one-time
tcpdump -i eth1 -nn -c 10 'udp port 51820'
```

While that runs, fire WG handshakes from a remote peer (e.g. clinic-vps). Expect to see lines like:

```
IP <peer-public-ip>.<src-port> > 192.168.0.157.51820: UDP, length 148
```

If packets arrive → Verizon is forwarding correctly.

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| 0 packets in tcpdump on GL-MT6000 | Verizon rule not active OR upstream blocked OR CGNAT | Verify the rule is saved; check Verizon WAN IP matches DDNS resolution; confirm not CGNAT |
| Packets arrive at GL-MT6000 but WG handshake fails | OpenWRT firewall drops them | Runbook 03 covers the `Allow-WireGuard-VPS` rule |
| WG handshake works but DGX unreachable from peer | LAN forwarding rule missing | Runbook 03 covers the `/etc/firewall.user` FORWARD rules |

## CGNAT check (one-time)

```bash
# On GL-MT6000:
ssh root@192.168.8.1 'curl -s https://api.ipify.org; echo'
# On any external host:
dig +short xr5899d.glddns.com
```

Both should print the same IPv4. If they differ, Verizon is CGNAT-ing this account → port-forwarding cannot work, pivot to Tailscale / Cloudflare Tunnel / Verizon static IP.

Confirmed 2026-05-29: this account has a real public IP, NOT CGNAT.

## Undo

In the Verizon admin, delete the `WireGuard` Port Forwarding rule.

## Why no playbook

The Verizon Business Gateway admin UI exposes no SSH or documented API. Manual GUI is the only path.
