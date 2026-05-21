# Runbook 03 — Wire a new marvelousempire app behind nginx

The `wire-marvelous-app.sh` generator turns "stand up a new app on the VPS" from ~30 minutes of operator work into ~5.

## When to use it

Any time you want to expose a marvelousempire app at `<name>.yousirjuan.ai` behind nginx + auto-start under systemd. Examples in the current footprint that fit this pattern: clinic, dockyard, scene-skout, ruflo, membadat.

**Don't use it for:** apps already in Docker (use docker-compose), apps that need GPU (separate concern), apps that are externally hosted (Tailscale Funnel target a different way).

## Usage

```bash
ssh vps-godaddy '
  sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/wire-marvelous-app.sh \
    --name <appname> \
    --bin "/usr/bin/python3 /opt/<appname>/server.py --host 127.0.0.1 --port <port>" \
    --port <port> \
    --vhost <appname>.yousirjuan.ai \
    --user abrownsanta \
    --working-dir /opt/<appname>
'
```

Real example (today's clinic install):

```bash
sudo bash playbooks/wire-marvelous-app.sh \
  --name clinic \
  --bin "/usr/bin/python3 /opt/clinic/server.py --host 127.0.0.1 --port 5436" \
  --port 5436 \
  --vhost clinic.yousirjuan.ai
```

## What it does

1. Renders `_template/python-app.service` with operator values → `/etc/systemd/system/<name>.service`
2. `systemctl enable --now <name>.service` (auto-on, restart on failure)
3. Verifies the upstream port is listening (warns if not)
4. Backs up any pre-existing `/etc/nginx/sites-enabled/<vhost>` to `/etc/nginx/sites-backups/`
5. Renders `_template/marvelous-vhost.conf` → `/etc/nginx/sites-enabled/<vhost>`
6. `nginx -t` + `nginx -s reload`
7. Probes `https://<vhost>/` and prints the result

## After it runs

If the verify step shows `HTTP 000` or 502, the most common cause is **no TLS cert yet**. Obtain one:

```bash
sudo certbot --nginx -d <vhost>
```

Then re-test:

```bash
curl -sI https://<vhost>/
```

## Undo

```bash
sudo bash playbooks/wire-marvelous-app.sh --name <name> --vhost <vhost> --undo
```

Removes the systemd unit + nginx vhost. Log file at `/var/log/<name>.log` is preserved. Backups under `/etc/nginx/sites-backups/` are preserved.

## What stays for the operator to do

- TLS cert via certbot (one-time per vhost)
- DNS A record at GoDaddy (one-time per vhost)
- Source code at `/opt/<name>/` must already exist (the script doesn't clone)

## Related

- [01-the-clinic-misconfig-story.md](01-the-clinic-misconfig-story.md) — the incident that motivated this generator
- [02-audit-output-2026-05-21.md](02-audit-output-2026-05-21.md) — the audit that surfaces vhosts whose upstreams are dead
- ADR-0001 — when this generator is the right tool vs Docker sandbox (LEDGER-0010)
