# 05 — WireGuard Mesh — add peers

## Why

Every device that needs off-LAN reach into the family network joins the mesh as a `[Peer]` on the GL-MT6000 + has its own client `wg0.conf`.

## Convention

| Peer | WG IP | Notes |
|---|---|---|
| GL-MT6000 (server) | 10.0.0.1 | not technically a peer |
| MacBook Pro | 10.0.0.2 | operator dev surface |
| iPhone | 10.0.0.3 | mobile |
| GL-AX1800 | 10.0.0.4 | IoT mesh AP |
| clinic-vps | 10.0.0.5 | public chat surface |
| (next) | 10.0.0.6+ | future peers |

## Steps to add a NEW peer

### 1. On the new peer device — generate keypair

```bash
sudo umask 077
sudo bash -c 'wg genkey | tee /etc/wireguard/<peer-name>_private.key | wg pubkey > /etc/wireguard/<peer-name>_public.key'
cat /etc/wireguard/<peer-name>_public.key
```

The public key prints; copy it.

### 2. On the GL-MT6000 (SSH)

Use the playbook from LEDGER-0026:

```bash
bash ledger/LEDGER-0026-vps-into-wg-mesh/playbooks/add-wg-peer-to-glinet.sh \
  --name <peer-name> \
  --pubkey <public-key> \
  --wg-ip 10.0.0.<N>
```

That adds the peer to the live `wg0` interface AND persists to `/etc/wireguard/wg0.conf`.

### 3. On the new peer — write `/etc/wireguard/wg0.conf`

Use the template:

```bash
sudo bash -c "cat > /etc/wireguard/wg0.conf <<EOF
[Interface]
PrivateKey = \$(cat /etc/wireguard/<peer-name>_private.key)
Address = 10.0.0.<N>/24

[Peer]
PublicKey = Be87LSRYnvURzDNnnHOCWdfUC/o5tDkaxrdJmEU0iAI=
Endpoint = xr5899d.glddns.com:51820
AllowedIPs = 10.0.0.0/24, 192.168.8.0/24
PersistentKeepalive = 25
EOF"
sudo chmod 600 /etc/wireguard/wg0.conf
sudo systemctl enable --now wg-quick@wg0
```

(On macOS, install `wireguard-tools` via Homebrew and use the WireGuard app; on iPhone, scan a QR code generated from the .conf.)

### 4. Verify handshake

On the new peer:

```bash
sudo wg show wg0
```

Expect `latest handshake: <few seconds ago>` and growing `transfer:` counters.

## Server public key (always the same)

```
Be87LSRYnvURzDNnnHOCWdfUC/o5tDkaxrdJmEU0iAI=
```

## Endpoint (always the same)

```
xr5899d.glddns.com:51820
```

## AllowedIPs convention for clients

```
AllowedIPs = 10.0.0.0/24, 192.168.8.0/24
```

This routes the WG subnet (so peers can reach each other) AND the home LAN (so peers can reach the DGX at `192.168.8.249`).

## Success criteria

- `wg show wg0` on the peer shows recent handshake
- `ping 10.0.0.1` from the peer succeeds
- `ping 192.168.8.249` from the peer succeeds (DGX reachable)

## Undo

### On the GL-MT6000

```bash
ssh root@192.168.8.1
wg set wg0 peer <peer-public-key> remove
sed -i "/<peer-public-key>/,+3d" /etc/wireguard/wg0.conf
```

### On the peer

```bash
sudo systemctl disable --now wg-quick@wg0
sudo rm /etc/wireguard/wg0.conf /etc/wireguard/<peer-name>_*.key
```
