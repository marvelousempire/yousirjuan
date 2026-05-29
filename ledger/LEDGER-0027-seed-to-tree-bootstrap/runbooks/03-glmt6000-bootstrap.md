# 03 — GL-MT6000 (Flint 2 / AX6000) Bootstrap

## Why

The GL-MT6000 is the family's primary router: LAN gateway, WireGuard server, DDNS client, OpenWRT firewall. This runbook turns a factory-reset device into the configured state our deployment depends on.

## Steps (admin UI portion — GUI, can't be scripted)

1. Power on, connect a wired Mac to one of the LAN ports.
2. Browser → `https://192.168.8.1`. Initial admin password = printed on device sticker; CHANGE IT on first login.
3. **System → Time Zone**: set Eastern (America/New_York).
4. **Network → LAN**: confirm subnet `192.168.8.0/24`, gateway `192.168.8.1`.
5. **Network → DHCP**: enabled, range e.g. `192.168.8.100–192.168.8.250`. Reserve `192.168.8.249` for DGX wired (by MAC).
6. **Applications → Dynamic DNS** (NOT Cloud Services): toggle ON, accept ToS, Apply. Note the auto-assigned `<uuid>.glddns.com` hostname (current: `xr5899d.glddns.com`).
7. **System → Security → Remote Access Control**: turn OFF HTTPS Remote Access AND SSH Remote Access. LAN-side admin still works.
8. **VPN → WireGuard Server** (the built-in 10.1.0.0/24 instance): leave OFF — we don't use this. The active WG server is wg-quick-managed (see runbook 05).

## Steps (CLI portion via SSH — these CAN be scripted)

Once you've set the admin password, SSH in:

```bash
ssh root@192.168.8.1
```

### Install tcpdump (for diagnostics later)

```bash
opkg update && opkg install tcpdump-mini
```

### Persist firewall rules for the WireGuard mesh

```bash
F=/etc/firewall.user
echo "iptables -I FORWARD 1 -i wg0 -d 192.168.8.0/24 -j ACCEPT" >> $F
echo "iptables -I FORWARD 1 -i br-lan -s 192.168.8.0/24 -d 10.0.0.0/24 -j ACCEPT" >> $F
chmod +x $F
cat $F
```

The first echo allows WG-to-LAN forwarding; the second allows LAN responses back through WG. Both rules survive every `fw3 restart` and every reboot.

### Attach wg0 to the LAN firewall zone

```bash
uci add_list firewall.@zone[0].device='wg0'
uci commit firewall
/etc/init.d/firewall restart
```

### Add the inbound allow rule for the WireGuard listening port

```bash
uci add firewall rule
uci set firewall.@rule[-1].name='Allow-WireGuard-VPS'
uci set firewall.@rule[-1].src='wan'
uci set firewall.@rule[-1].proto='udp'
uci set firewall.@rule[-1].dest_port='51820'
uci set firewall.@rule[-1].target='ACCEPT'
uci commit firewall
/etc/init.d/firewall restart
```

### Bootstrap the WireGuard server (wg-quick)

```bash
mkdir -p /etc/wireguard
cd /etc/wireguard
umask 077
wg genkey | tee server_private.key | wg pubkey > server_public.key
cat > wg0.conf <<EOF
[Interface]
PrivateKey = $(cat server_private.key)
ListenPort = 51820
EOF
chmod 600 wg0.conf
```

Then for each peer (Mac, iPhone, AX1800, VPS), follow runbook 05 to append a `[Peer]` block.

### Enable wg-quick on boot

```bash
cat > /etc/init.d/wg-quick-wg0 <<'EOF'
#!/bin/sh /etc/rc.common
START=99
start() { wg-quick up wg0; }
stop()  { wg-quick down wg0; }
EOF
chmod +x /etc/init.d/wg-quick-wg0
/etc/init.d/wg-quick-wg0 enable
/etc/init.d/wg-quick-wg0 start
```

## Success criteria

```bash
wg show wg0                     # interface up, ready for peers
iptables -L FORWARD -v -n | grep -E "wg0|192.168.8" | head -5   # 2 rules present
ip neigh show dev br-lan | wc -l   # > 5 (LAN clients)
```

DDNS hostname resolves to current WAN IP:

```bash
dig +short xr5899d.glddns.com
```

## Undo

Factory reset the GL-MT6000 (10-second hold on the reset button) → re-run this runbook from step 1.
