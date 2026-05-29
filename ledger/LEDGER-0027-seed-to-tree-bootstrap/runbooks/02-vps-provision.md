# 02 — VPS Provision (GoDaddy `clinic-vps`)

## Why

The public surface at `nephew.yousirjuan.ai` runs from a small Ubuntu VPS. This runbook gets a fresh VPS to "ready for everything else."

## Prereqs

- A GoDaddy VPS or any provider offering Ubuntu 22.04+ with public IPv4
- A `nephew.yousirjuan.ai` DNS A record pointing to the VPS IP
- Operator SSH access (key-based, port 22 or 2222)

## Steps

### 1. First login + harden

```bash
ssh root@<vps-ip>
adduser abrownsanta
usermod -aG sudo abrownsanta
mkdir -p ~abrownsanta/.ssh
cp ~/.ssh/authorized_keys ~abrownsanta/.ssh/
chown -R abrownsanta:abrownsanta ~abrownsanta/.ssh
chmod 700 ~abrownsanta/.ssh
chmod 600 ~abrownsanta/.ssh/authorized_keys
```

Edit `/etc/ssh/sshd_config`:
- `PermitRootLogin no`
- `PasswordAuthentication no`

`systemctl restart ssh`.

### 2. Run the VPS bootstrap playbook

From the operator's Mac:

```bash
scp ledger/LEDGER-0027-seed-to-tree-bootstrap/playbooks/vps-bootstrap.sh clinic-vps:/tmp/
ssh clinic-vps 'sudo bash /tmp/vps-bootstrap.sh'
```

That installs: `wireguard-tools`, `nginx`, `nodejs` (20.x), `iptables-persistent`, `certbot`, and clones the `marvelousempire/nephew` repo to `/opt/nephew`.

### 3. TLS cert via Let's Encrypt

```bash
ssh clinic-vps 'sudo certbot --nginx -d nephew.yousirjuan.ai -m operator@example.com --agree-tos --non-interactive'
```

### 4. Operator config

```bash
ssh clinic-vps '
mkdir -p ~/.nephew
cat > ~/.nephew/tower.env <<EOF
NEPHEW_OPERATOR_NAME=Avery Goodman
NEPHEW_OPERATOR_EMAIL=shade_worries_0c@icloud.com
NEPHEW_HERMES_KEY=v7pQ40f8zgfW-O7xy9y_vMgmy5LAzoZdr-pEOC1UjZI
EOF
chmod 600 ~/.nephew/tower.env
'
```

### 5. Start tower-api

```bash
ssh clinic-vps '
systemctl --user enable --now nephew-tower-api
sleep 2
systemctl --user is-active nephew-tower-api
'
```

Then continue to runbook 05 (WireGuard) and runbook 07 (nephew CT deploy).

## Success criteria

```bash
ssh clinic-vps 'systemctl --user is-active nephew-tower-api'
# active
curl -fI https://nephew.yousirjuan.ai/
# HTTP/2 200 with valid TLS
```

## Undo

```bash
# At the cloud provider — destroy and rebuild the VPS, then restart runbook 02 from step 1
```
