# 03 — Deploy the credential to vps-godaddy

## Goal

Land the PAT generated in runbook 02 at `/etc/yousirjuan-sync/credentials` on vps-godaddy with `0600 root:root` permissions. The installer is idempotent — re-run it any time the token rotates.

## Steps

1. **SSH to vps-godaddy.**
2. **Pull latest yousirjuan** so the playbook is current:
   ```
   cd ~/Developer/yousirjuan && git pull --ff-only
   ```
3. **Run the installer interactively** (keeps the token out of shell history):
   ```
   sudo bash ledger/LEDGER-0025-vps-marvelousempire-deploy-key/playbooks/install-credential.sh
   ```
4. **Paste the token at the prompt** ("Paste GitHub fine-grained PAT (input hidden):") and press Enter. Input is suppressed — your terminal won't echo it.
5. **Watch the smoke test.** The installer makes one API call to `/orgs/marvelousempire`. Expected output:
   ```
   ✓ token authenticates to marvelousempire org
   ```

## What the installer does

- Creates `/etc/yousirjuan-sync/` (mode `0700`, owned by `root:root`) if missing
- Writes the credentials file atomically (via `mktemp` + `mv`) so a partial write can't corrupt state
- Validates the token's shape (warns if it doesn't match `ghp_…` / `github_pat_…`)
- Smoke-tests the token against `GET /orgs/marvelousempire` and dies clearly on 401 / 403 / 404

## Success criteria

```
sudo cat /etc/yousirjuan-sync/credentials | head -1
# Expected: a comment line "# LEDGER-0025 — GitHub PAT ..."

sudo stat -c '%a %U:%G' /etc/yousirjuan-sync/credentials
# Expected: "600 root:root"
```

The installer's own smoke test (Step 5 above) is the authoritative end-to-end check.

## Undo

```
sudo rm -f /etc/yousirjuan-sync/credentials
```

Without the file, `sync-and-drift.sh` falls back to the SSH URL (which will fail again — back to the pre-LEDGER-0025 state). To fully revert: also revoke the PAT in GitHub.

## Next

Runbook 04 — confirm `sync-and-drift.sh` picks up the credential and switches to HTTPS URLs.
