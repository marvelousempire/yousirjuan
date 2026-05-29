# 01 — Generate the VPS WireGuard keypair on `clinic-vps`

## Why

Every WG peer needs its own keypair. The private key MUST stay on the device it represents — never copy it elsewhere. This step creates the pair on `clinic-vps` so the private key never leaves the VPS.

## Steps

From the operator's Mac:

```bash
ssh clinic-vps 'sudo bash -c "command -v wg >/dev/null || (apt-get update -qq && apt-get install -y -qq wireguard-tools); wg genkey | tee /etc/wireguard/clinic-vps_private.key | wg pubkey | tee /etc/wireguard/clinic-vps_public.key && chmod 600 /etc/wireguard/clinic-vps_private.key && chmod 644 /etc/wireguard/clinic-vps_public.key && echo PUBKEY_END"'
```

The single emitted base64 line above `PUBKEY_END` is the VPS public key — give that to runbook 02.

## Success criteria

- `/etc/wireguard/clinic-vps_private.key` exists on the VPS with mode 600
- `/etc/wireguard/clinic-vps_public.key` exists with mode 644
- The private key file is owned by `root:root`
- `sudo cat /etc/wireguard/clinic-vps_public.key` returns a 44-char base64 string ending in `=`

## Undo

```bash
ssh clinic-vps 'sudo rm /etc/wireguard/clinic-vps_*.key'
```

(Only safe if the VPS isn't already actively running `wg-quick@wg0` against this key — bring `wg0` down first.)
