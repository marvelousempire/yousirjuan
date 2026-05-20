# Runbook 02 — Deploy the standby container on the iMac

**Time:** ~10 minutes total (2 GB image download + 3-5 min GitLab first-boot)
**Reversible:** yes (`docker compose down` + delete `~/Library/GitLab-Data/`)
**Prereqs:** runbook 01 complete (OrbStack running, Tailscale online, Energy Saver configured)

## What this does

Lays down the docker-compose, creates the data volume layout, pulls the GitLab CE image (pinned to the same digest as VPS primary), starts the container. After this, the standby is running with an EMPTY GitLab — first nightly restore cycle (run by launchd) hydrates it from VPS backup.

## Steps

The install playbook does all of this. Just run:

```bash
bash ~/Developer/yousirjuan/ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh install
```

What it does, step-by-step:

1. Checks prereqs (docker on PATH, rsync, Tailscale state).
2. Creates `~/Developer/gitlab-standby/` and `~/Library/GitLab-Data/{config,data,logs,data/backups}/`.
3. Copies the canonical [`artifacts/docker-compose.yml`](../artifacts/docker-compose.yml) to `~/Developer/gitlab-standby/`.
4. Copies the two LaunchAgent plists to `~/Library/LaunchAgents/` and loads them.
5. `docker compose pull` — downloads `gitlab/gitlab-ce:latest@sha256:c66669ef…` (~2 GB).
6. `docker compose up -d` — starts `gitlab-standby` container.

GitLab's first boot inside the container takes 3–5 minutes (Postgres init, gitlab-shell setup, etc.). Watch progress:

```bash
docker logs -f gitlab-standby
```

When you see `==> /var/log/gitlab/gitlab-rails/production.log <==` lines stop scrolling, it's mostly ready. Confirm:

```bash
curl -sI http://localhost:8929/
```

Should return `HTTP/1.1 302 Found` with `Location: http://imac-avery.tailaa31dd.ts.net:8929/users/sign_in`.

From another tailnet machine, the same works on the hostname:

```bash
curl -sI http://imac-avery.tailaa31dd.ts.net:8929/
```

## Success criteria

- `bash …/install-standby.sh status` shows ✓ for: prereqs, container running, HTTP responding, both launchd agents loaded.
- `docker ps` lists `gitlab-standby` as `Up X minutes (healthy)`.
- Tailnet machines can reach `http://imac-avery.tailaa31dd.ts.net:8929/`.
- GitLab is empty (no users / projects yet — that's expected; first restore brings the data).

## Notes

- **The standby is EMPTY at this point.** Logging into the web UI shows the GitLab first-run setup screen. Don't create users / projects manually — the first nightly restore overwrites it with VPS state.
- **External_url in the compose** uses `http://imac-avery.tailaa31dd.ts.net:8929`. If your tailnet hostname differs (Tailscale-renamed your iMac), edit `~/Developer/gitlab-standby/docker-compose.yml` and re-run `docker compose up -d`.
- **SSL inside the tailnet** isn't necessary — Tailscale encrypts all traffic between tailnet peers (WireGuard). HTTPS would require a different cert path (Tailscale Funnel + ACME), out of scope.
- **Port 2424** is exposed on the host for git-SSH. Same port as VPS, so muscle memory is preserved.

## Undo

```bash
bash ~/Developer/yousirjuan/ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh uninstall
# Data preserved at ~/Library/GitLab-Data/. To wipe entirely:
rm -rf ~/Library/GitLab-Data
```

## Related

- Previous: [01-prereqs-on-imac.md](01-prereqs-on-imac.md)
- Next: [03-backup-replication.md](03-backup-replication.md) — how the nightly cycle keeps standby in sync
