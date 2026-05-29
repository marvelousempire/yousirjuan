# 04 — Port-forward UDP/51820 on the Verizon Business Internet Gateway

## Why

The Verizon Business Internet Gateway sits upstream of the GL-MT6000 and holds the public WAN IP. The GL-MT6000's WAN interface gets a private IP from Verizon (`192.168.0.157` on `eth1`, `192.168.0.162` on `apclix0`). For off-LAN peers to reach the WG server, Verizon must forward UDP/51820 to the GL-MT6000's WAN-side IP.

## Steps

1. Open `https://192.168.0.1` in a browser. Log in with the admin password from the device sticker.
2. Navigate to **Security & Firewall → Port Forwarding** (or the equivalent on your firmware).
3. **Create Rule:**
   - Application: `WireGuard`
   - Protocol: `UDP`
   - Original Port: `51820`
   - Fwd to Addr: `192.168.0.157`
   - Fwd to Port: `51820`
4. Save / Apply.

## Success criteria

From a host OUTSIDE the home LAN (e.g. `clinic-vps`):

```bash
# WG handshake completes within ~30 seconds (persistent keepalive cadence)
sudo wg show wg0
# expected: "latest handshake: <a few seconds ago>" and "transfer: X received, Y sent" with X > 0
```

## Troubleshooting

If `transfer: 0 B received` after multiple keepalive cycles:

1. **Confirm the rule's internal IP matches the GL-MT6000's default-route interface.**
   On the GL-MT6000: `ip route | head -3` — the `default via` interface is the one return packets exit through. If the rule targets `eth1`/`192.168.0.157` but the default route is `apclix0`/`192.168.0.162`, the asymmetric routing will be dropped by Verizon's stateful firewall.

2. **Lower Verizon's firewall security level.** Many Verizon Business Gateways drop unsolicited UDP even when port-forwarded if Security Level is High or "Stealth Mode" / "Anti port-scan" is enabled. Test by lowering to Low or Medium.

3. **Suspect CGNAT.** Verizon 5G Business Internet plans frequently use CGNAT — meaning the public IP shown by DDNS is shared across many customers and inbound is fundamentally impossible. Check the WAN IP shown by the Verizon admin: if it's in `100.64.0.0/10` or a private range that doesn't match what DDNS reports, you're CGNAT'd. Options: add a static IP to the Verizon plan, OR switch architectures to Tailscale / Cloudflare Tunnel.

## Undo

In the Verizon admin's Port Forwarding panel, delete the `WireGuard` rule.

## Why no playbook

The Verizon Business Internet Gateway admin UI does not expose SSH or a documented API. Configuration must be done through the web UI by a human with the device sticker password.
