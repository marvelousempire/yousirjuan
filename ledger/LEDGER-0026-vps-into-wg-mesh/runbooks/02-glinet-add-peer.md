# 02 — Add the VPS peer to the GL-MT6000's WireGuard server

## Why

The GL-MT6000 (AX6000 / Flint 2) hosts the family WG server at `10.0.0.0/24` via `wg-quick`, config at `/etc/wireguard/wg0.conf`. The peer must be added to BOTH the running interface (immediate effect) AND the config file (survives reboot).

**Important:** the GL.iNet has a SEPARATE "WireGuard Server" UI under VPN → WireGuard Server that uses the `10.1.0.0/24` subnet — that instance is currently OFF and is NOT what we use. The active server is the `wg-quick`-managed instance on `wg0` at `10.0.0.0/24`. Adding peers through the GL.iNet UI would land them on the wrong server.

## Steps

```bash
ssh root@192.168.8.1
# Password: GL.iNet admin password

# Live-add the peer (takes effect immediately, lost on reboot)
wg set wg0 peer <VPS_PUBLIC_KEY> allowed-ips 10.0.0.X/32 persistent-keepalive 25

# Persist to /etc/wireguard/wg0.conf (paste-safe single-line echos)
echo "" >> /etc/wireguard/wg0.conf
echo "[Peer]" >> /etc/wireguard/wg0.conf
echo "# <peer-name>" >> /etc/wireguard/wg0.conf
echo "AllowedIPs = 10.0.0.X/32" >> /etc/wireguard/wg0.conf
echo "PersistentKeepalive = 25" >> /etc/wireguard/wg0.conf
K=<VPS_PUBLIC_KEY>
echo "PublicKey = $K" >> /etc/wireguard/wg0.conf
```

The variable-into-echo pattern dodges paste-line-wrap traps that break heredocs and `printf` on busy terminals.

## Success criteria

- `wg show wg0` lists the new peer with `allowed ips: 10.0.0.X/32` and `persistent keepalive: every 25 seconds`
- `tail -8 /etc/wireguard/wg0.conf` shows a `[Peer]` block with the matching `PublicKey`, `AllowedIPs`, and `PersistentKeepalive` lines

## Undo

```bash
ssh root@192.168.8.1
wg set wg0 peer <VPS_PUBLIC_KEY> remove
# Then manually edit /etc/wireguard/wg0.conf and delete the [Peer] block
```

## Notes

- The GL-MT6000's WG server public key is `Be87LSRYnvURzDNnnHOCWdfUC/o5tDkaxrdJmEU0iAI=` — peers need this in their own client config as `[Peer] PublicKey = ...`.
- WG IP assignment convention: `.2` Mac, `.3` iPhone, `.4` AX1800, `.5` clinic-vps. Future peers pick the next unused `.X` in `10.0.0.0/24`.
