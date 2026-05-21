# Runbook 01 — The clinic.yousirjuan.ai misconfig story

A small-scale postmortem in the LEDGER-0007 runbook-05 style.

## Symptom

After stopping the GitLab Docker container intentionally (2026-05-20), `clinic.yousirjuan.ai` returned **HTTP 502 Bad Gateway** even though The Clinic is a separate product with its own source at `/opt/clinic/`.

## Diagnosis (~3 minutes)

```bash
ssh vps-godaddy 'grep proxy_pass /etc/nginx/sites-enabled/clinic.yousirjuan.ai'
# →   proxy_pass http://127.0.0.1:8929;

ssh vps-godaddy 'grep proxy_pass /etc/nginx/sites-enabled/git.yousirjuan.ai'
# →   proxy_pass http://127.0.0.1:8929;
```

Both `clinic.yousirjuan.ai` and `git.yousirjuan.ai` were pointing at port **8929 — GitLab's port**. When GitLab stopped, both vhosts started 502'ing because nginx couldn't reach the upstream.

## Root cause

A prior session copied the `git.yousirjuan.ai` nginx vhost as a template for `clinic.yousirjuan.ai`, kept the wrong `proxy_pass`, and the misconfig was never caught because nobody was running an upstream-liveness audit.

## Fix

1. Started The Clinic on its actual port (5436) under systemd:

   ```bash
   sudo systemctl enable --now clinic.service
   ```

2. Repointed nginx:

   ```bash
   sudo sed -i "s|proxy_pass http://127.0.0.1:8929;|proxy_pass http://127.0.0.1:5436;|g" \
     /etc/nginx/sites-enabled/clinic.yousirjuan.ai
   sudo nginx -t && sudo nginx -s reload
   ```

3. Verified: `clinic.yousirjuan.ai` → 200 in 67 ms.

## Why this turned into LEDGER-0013

The fix itself was 3 commands. The structural insight was: **no one was auditing whether nginx vhosts pointed at backends that were actually running.** That's a systemic gap. So in addition to fixing clinic, this ledger entry ships:

1. The fix as a concrete artifact (clinic.service + clinic.yousirjuan.ai nginx config)
2. A reusable generator (`wire-marvelous-app.sh`) so the next app takes 5 min instead of 30 + can't have this kind of port-mismatch silently
3. An audit playbook (`audit-vhost-upstreams.sh`) that surfaces every dead upstream on the box in one read-only command

## Bonus finding

Running the audit immediately surfaced **two more dead upstreams** the operator didn't know about:

- `massillon-legal` → `:3010` (nothing listening)
- `thebriefcase.app` → Docker container `quick_server_br…` (container stopped)

See [02-audit-output-2026-05-21.md](02-audit-output-2026-05-21.md).

## Lesson

When you accidentally take down a service in production, **also check what else is pointed at it.** nginx's vhost graph is a hidden dependency map. Running a one-line audit on the box every time you stop or move a service surfaces these in seconds.
