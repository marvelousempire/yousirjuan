# 04 — Teach sync-and-drift.sh to use the credential

## Goal

`sync-and-drift.sh` reads `/etc/yousirjuan-sync/credentials` at start-of-run and rewrites the GitHub URL base from `git@github.com:marvelousempire` (SSH, which fails) to `https://x-access-token:<token>@github.com/marvelousempire` (HTTPS with token, which works).

This is **automatic** — the script change shipped in the same PR as runbook 02/03. No manual editing required.

## How it works

At the top of `sync-and-drift.sh`:

```bash
CREDENTIALS_FILE="${CREDENTIALS_FILE:-/etc/yousirjuan-sync/credentials}"

GITHUB_TOKEN=""
if [ -r "$CREDENTIALS_FILE" ]; then
  source "$CREDENTIALS_FILE"
fi
if [ -n "$GITHUB_TOKEN" ]; then
  GITHUB_URL_BASE="https://x-access-token:${GITHUB_TOKEN}@github.com/marvelousempire"
else
  GITHUB_URL_BASE="git@github.com:marvelousempire"  # fallback (still fails — but doesn't crash the script)
fi
```

Every iteration of `sync_one` then runs:

```bash
git remote set-url origin "$GITHUB_URL_BASE/$repo.git"
```

So even if the bare repos were cloned with the OLD SSH URL, the next sync tick re-points them to the HTTPS URL with the credential. **Automatic rotation:** edit `/etc/yousirjuan-sync/credentials`, wait 5 minutes, every bare repo's origin URL is updated.

## Deploy the script change

The script change shipped with this PR (LEDGER-0025 implementation). To pick it up on vps-godaddy:

```
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git pull --ff-only && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install'
```

`install.sh` is idempotent — it copies the updated `sync-and-drift.sh` into `/opt/yousirjuan-sync/`. The systemd timer picks it up on the next 5-min tick.

## Why the token sits in the URL (not a credential helper)

GitHub HTTPS with a PAT-in-URL is the simplest pattern that works for all `git` subcommands without per-command configuration. Trade-offs:

- **Pros:** zero git config; the URL is the contract; `git remote -v` shows what's happening.
- **Cons:** the token appears in `.git/config` of every bare repo. Acceptable here because the bare repos live at `/var/cache/yousirjuan-sync/` (`0700 root:root`) and are unreadable by anyone but root — same trust boundary as the credentials file.

For multi-tenant or higher-security contexts, the credential helper pattern (`git -c credential.helper='!f() {...}; f'`) keeps the token out of `.git/config`. Worth revisiting if this script ever runs as a non-root service user.

## Success criteria

```
ssh vps-godaddy 'sudo -u root git -C /var/cache/yousirjuan-sync/yousirjuan remote -v'
# Expected (after a sync cycle): origin URL starts with https://x-access-token:
```

## Undo

Revert the script change:

```
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git checkout <pre-LEDGER-0025-sha> -- ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install'
```

## Next

Runbook 05 — end-to-end verification.
