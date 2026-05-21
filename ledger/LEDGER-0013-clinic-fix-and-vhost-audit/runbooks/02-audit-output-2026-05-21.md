# Runbook 02 — VPS vhost-upstream audit output, 2026-05-21

Raw output from `audit-vhost-upstreams.sh` run on the GoDaddy VPS after the clinic fix landed.

```
VHOST                            EXT_HTTP  PROXY_PASS                 UPSTREAM
──────────────────────────────────────────────────────────────────────────────
clinic.yousirjuan.ai             200       http://127.0.0.1:5436      listening
default                          —         —                          ?
git.yousirjuan.ai                502       http://127.0.0.1:8929      ✗ DOWN
hello.yousirjuan.ai              200       http://127.0.0.1:3000      listening
massillon-legal                  —         http://127.0.0.1:3010      ✗ DOWN
nephew.yousirjuan.ai             200       http://127.0.0.1:8000      listening
readyplay-admin                  —         http://localhost:3002      listening
readyplay-api                    —         http://localhost:3001      listening
readyplay-marketing              —         http://localhost:3003      listening
readyplay-me                     —         http://127.0.0.1:3004      listening
thebriefcase.app                 —         http://quick_server_br…    ✗ DOWN
vhms-marketing                   —         http://localhost:3110      listening
workflow.yousirjuan.ai           502       http://127.0.0.1:5678      ✗ DOWN
```

## Per-vhost notes

| Vhost | Upstream | State | Recommended action |
|---|---|---|---|
| `clinic.yousirjuan.ai` | :5436 | ✓ NEWLY FIXED | none — keep auditing periodically |
| `git.yousirjuan.ai` | :8929 (GitLab) | ✗ intentionally stopped | restart GitLab when ready + mount the LEDGER-0011 caps fragment first |
| `workflow.yousirjuan.ai` | :5678 (n8n) | ✗ intentionally stopped | bring n8n back inside LEDGER-0010 sandbox (Docker), not on host |
| `massillon-legal` | :3010 | ✗ DOWN — **investigation needed** | what's :3010 supposed to be? source location? systemd unit? |
| `thebriefcase.app` | docker `quick_server_br…` | ✗ DOWN — **investigation needed** | container stopped; start it OR remove the vhost |

## How to investigate each unknown

For `massillon-legal`:

```bash
ssh vps-godaddy '
  ls /opt/massillon-legal 2>/dev/null
  systemctl list-units --all "massillon*" --no-legend
  grep -r "3010" /opt/massillon-legal/ 2>/dev/null | head -5
'
```

For `thebriefcase.app`:

```bash
ssh vps-godaddy '
  docker ps -a --filter "name=quick_server" --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"
  ls /opt/quick-server 2>/dev/null
  find /opt/quick-server -name "docker-compose*" 2>/dev/null | head -3
'
```

## Re-running the audit

```bash
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/audit-vhost-upstreams.sh'
```

Suggested cadence: weekly via cron, OR every time the operator stops/restarts any backend service.
