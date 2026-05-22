# Runbook 01 — install the dual-push drift sync on the VPS

## Prereqs

- VPS reachable via `ssh vps-godaddy`
- GitLab CE running at `127.0.0.1:2424` on the VPS (LEDGER-0005)
- A deploy SSH key on the VPS that can `git fetch` from `git@github.com:marvelousempire/<repo>.git` (read access to the org's private repos)

## Install

One block to paste:

```
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git pull --ff-only && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install'
```

## Verify

```
ssh vps-godaddy '\
  sudo systemctl list-timers yousirjuan-dual-push-sync.timer | head -5 && \
  echo --- && \
  sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  echo --- && \
  cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -30'
```

A clean report shows `"drift_corrected": 0` and `"failures": 0` once all repos are aligned.

## Test the drift response

Induce a fake drift on the VPS itself (no laptop required):

```
ssh vps-godaddy 'cd /tmp && rm -rf .test-drift && \
  git clone git@github.com:marvelousempire/dustpan.git .test-drift && \
  cd .test-drift && \
  git remote add gitlab ssh://git@127.0.0.1:2424/marvelousempire/dustpan.git && \
  git fetch gitlab && \
  git push --force-with-lease gitlab HEAD~1:main && \
  echo "induced drift; wait 5 min then check /var/log/yousirjuan-sync.log"'
```

After 5 min, the sync should detect + auto-correct the induced drift. Inspect the log to confirm.

## Undo

```
ssh vps-godaddy 'sudo bash ~/Developer/yousirjuan/ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh uninstall'
```
