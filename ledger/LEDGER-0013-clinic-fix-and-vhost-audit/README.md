---
ledgerId: LEDGER-0013
title: Clinic vhost fix + nginx vhost-upstream audit + reusable wire-marvelous-app generator
status: in-progress
opened: 2026-05-21
closed: null
related-pains: []
related-tickets: [LEDGER-0011, LEDGER-0012]
triggers:
  - manual-cli: `sudo bash ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/wire-marvelous-app.sh <name> <port>`
  - manual-cli: `sudo bash ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/audit-vhost-upstreams.sh`
---

# LEDGER-0013 — Clinic vhost fix + vhost audit + wire-marvelous-app generator

## Ask

In the 2026-05-21 session, the operator noticed `clinic.yousirjuan.ai` returning 502 after we intentionally stopped GitLab. Investigation surfaced a misconfigured nginx vhost: `clinic.yousirjuan.ai` was pointing at GitLab's port (`127.0.0.1:8929`) instead of `/opt/clinic/`'s actual server (port 5436). When GitLab stopped, clinic went down too.

The fix was straightforward. The systemic problem is bigger: **no one was auditing whether nginx vhosts pointed at backends that were actually running.** A vhost audit surfaced two more dead upstreams (`massillon-legal` on :3010, `thebriefcase.app` on a stopped container).

## Outcome

Three things shipped:

### 1. The Clinic now lives at clinic.yousirjuan.ai (HTTP 200, 67ms)

- New `clinic.service` systemd unit: runs `/opt/clinic/server.py --host 127.0.0.1 --port 5436`, auto-restart, survives reboot. 27 MB RSS.
- nginx vhost `clinic.yousirjuan.ai` repointed from `:8929` → `:5436`.
- Old config backed up at `/etc/nginx/sites-backups/clinic.yousirjuan.ai.bak-*`.

### 2. Reusable `wire-marvelous-app.sh` generator

```bash
sudo bash playbooks/wire-marvelous-app.sh \
  --name clinic \
  --bin "/usr/bin/python3 /opt/clinic/server.py --host 127.0.0.1 --port 5436" \
  --port 5436 \
  --vhost clinic.yousirjuan.ai
```

Generates from `_template/`:
- `/etc/systemd/system/<name>.service` (renders + enables)
- `/etc/nginx/sites-enabled/<vhost>` (renders + reloads nginx)
- Verifies upstream + HTTPS response

Next time you stand up a marvelousempire app on the VPS, ~5 min of operator work instead of ~30.

### 3. Audit playbook surfaces all dead upstreams

`audit-vhost-upstreams.sh` — for every nginx vhost: prints external HTTP code + proxy_pass target + whether the upstream port is actually `LISTEN`ing. Today's run found 4 dead:

| Vhost | Upstream | Why |
|---|---|---|
| `git.yousirjuan.ai` | :8929 | GitLab stopped today (intentional) |
| `workflow.yousirjuan.ai` | :5678 | n8n stopped today (intentional, LEDGER-0007 runbook 05 OOM trigger) |
| `massillon-legal` | :3010 | **investigation needed** — what's :3010? |
| `thebriefcase.app` | container `quick_server_br…` | **investigation needed** — Docker container stopped |

Run this audit weekly; pair it with the LEDGER-0012 `/sites` endpoint for live monitoring.

## Runbooks

- [01-the-clinic-misconfig-story.md](runbooks/01-the-clinic-misconfig-story.md) — diagnosis: how we found clinic was pointing at GitLab's port
- [02-audit-output-2026-05-21.md](runbooks/02-audit-output-2026-05-21.md) — the 4 dead upstreams + per-vhost recommended action
- [03-wire-a-new-marvelous-app.md](runbooks/03-wire-a-new-marvelous-app.md) — operator runbook: `wire-marvelous-app.sh` usage

## Playbooks

- [wire-marvelous-app.sh](playbooks/wire-marvelous-app.sh) — systemd + nginx generator. Idempotent. `--undo` removes the unit + vhost.
- [audit-vhost-upstreams.sh](playbooks/audit-vhost-upstreams.sh) — per-vhost upstream-liveness report. Pure read-only. Output is the table at the top of this ticket.

## Artifacts

- [_template/python-app.service](artifacts/_template/python-app.service) — systemd unit template for any `/opt/<app>/server.py`-style app
- [_template/marvelous-vhost.conf](artifacts/_template/marvelous-vhost.conf) — nginx vhost template
- [clinic.service](artifacts/clinic.service) — concrete instance shipped today
- [clinic.yousirjuan.ai](artifacts/clinic.yousirjuan.ai) — concrete vhost shipped today

## Replay (zero-AI, on a fresh VPS)

```bash
# Audit first to know the current state
sudo bash ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/audit-vhost-upstreams.sh

# Wire The Clinic
sudo bash ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/wire-marvelous-app.sh \
  --name clinic \
  --bin "/usr/bin/python3 /opt/clinic/server.py --host 127.0.0.1 --port 5436" \
  --port 5436 \
  --vhost clinic.yousirjuan.ai \
  --user abrownsanta
```

## Verification

```bash
systemctl is-active clinic.service             # active
curl -sf http://127.0.0.1:5436/health || true  # 200 or 404 — server up
curl -sf -o /dev/null -w '%{http_code}\n' https://clinic.yousirjuan.ai/   # 200
sudo bash playbooks/audit-vhost-upstreams.sh | grep clinic   # clinic 200 :5436 listening
```

## Undo

```bash
sudo bash ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/wire-marvelous-app.sh \
  --name clinic --vhost clinic.yousirjuan.ai --undo
```

Removes the systemd unit + nginx vhost. The pre-existing backup at `/etc/nginx/sites-backups/clinic.yousirjuan.ai.bak-*` (auto-created on first apply) can be restored manually if you want the old GitLab-pointing config back.

## Open follow-ups

- **Investigate `massillon-legal` :3010** — is this supposed to be a separate app? Where's its source? Should the service exist?
- **Investigate `thebriefcase.app`** — the upstream Docker container is named `quick_server_br…`; probably the marvelousempire/quick-server. Start the container OR remove the vhost.
- **Schedule the audit** — add a launchd job on the iMac that runs the audit weekly and posts to Nephew Control Tower if any new dead upstream appears.
- **LEDGER-0012 /sites should drive a notification** — when an EXPECTED-up vhost returns 5xx for >3 consecutive ticks, fire the Phase-3 osascript notification (LEDGER-0012 follow-up).

## Cross-references

- [LEDGER-0007 runbook 05](../LEDGER-0007-imac-emergency-failsafe/runbooks/05-incident-2026-05-20-oom-cascade.md) — the OOM incident that motivated stopping GitLab + n8n, which is what surfaced the clinic misconfig
- [LEDGER-0012](../LEDGER-0012-vps-observability-control/) — VPS observability surface; `/sites` endpoint complements this ticket's audit script
- ADR-0001 — selective Docker philosophy; clinic stays native systemd because it's a 27 MB stdlib Python server (Docker would add overhead, no isolation gain)
