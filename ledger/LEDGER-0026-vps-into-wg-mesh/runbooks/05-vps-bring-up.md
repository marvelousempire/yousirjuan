# 05 — Install wireguard-tools and bring up `wg-quick@wg0` on `clinic-vps`

## Why

With the keypair generated (runbook 01) and the GL-MT6000 expecting our public key (runbook 02), the VPS needs a `/etc/wireguard/wg0.conf` that uses the existing private key and points at the server's DDNS hostname.

## Steps

From the operator's Mac:

```bash
ssh clinic-vps 'sudo bash -c "
PRIV=\$(cat /etc/wireguard/clinic-vps_private.key)
cat > /etc/wireguard/wg0.conf <<EOF
# Plan 0090 — VPS joins family WG mesh (10.0.0.0/24)

[Interface]
PrivateKey = \$PRIV
Address = 10.0.0.5/24

[Peer]
PublicKey = Be87LSRYnvURzDNnnHOCWdfUC/o5tDkaxrdJmEU0iAI=
Endpoint = xr5899d.glddns.com:51820
AllowedIPs = 10.0.0.0/24, 192.168.8.0/24
PersistentKeepalive = 25
EOF
chmod 600 /etc/wireguard/wg0.conf
chown root:root /etc/wireguard/wg0.conf
systemctl enable --now wg-quick@wg0
"'
```

The heredoc reads the private key directly from disk inside the same SSH session — the key never crosses the operator's terminal or the chat.

## Success criteria

```bash
ssh clinic-vps 'sudo wg show wg0'
# expected:
# interface: wg0
#   public key: 57VEld4KHjzGLuKa+jx3yBzQMhy4whePxWGZDa1gQwQ=
# peer: Be87LSRYnvURzDNnnHOCWdfUC/o5tDkaxrdJmEU0iAI=
#   endpoint: <Verizon WAN IP>:51820
#   latest handshake: <a few seconds ago>
#   transfer: X received, Y sent  (X > 0)

ssh clinic-vps 'ping -c 3 192.168.8.249'
# expected: 3 packets received, 0% packet loss

ssh clinic-vps 'curl -s http://192.168.8.249:8642/v1/models | head -c 200'
# expected: JSON model list including "qwen2.5:32b"
```

## Undo

```bash
ssh clinic-vps 'sudo systemctl disable --now wg-quick@wg0; sudo rm /etc/wireguard/wg0.conf'
```

## Notes

- `wg-quick` reads the private key from disk at boot; no daemon needs the file in memory after start.
- VPS's WG listen port is ephemeral (kernel-assigned each boot) — only the GL-MT6000's listen port matters for inbound.
- If the handshake doesn't complete, fall back to runbook 04's troubleshooting section — the most common cause is an upstream firewall, not the VPS config.
