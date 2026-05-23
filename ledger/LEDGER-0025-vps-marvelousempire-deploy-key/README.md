---
ledgerId: LEDGER-0025
title: VPS deploy-key for marvelousempire — let sync-and-drift.sh clone any repo
status: planning
opened: 2026-05-22
closed: null
related-pains: []
related-tickets: [LEDGER-0024]
triggers: []
---

# LEDGER-0025 — VPS deploy-key for marvelousempire

## Ask

After LEDGER-0024 v0.2.2 made the dual-push drift report JSON parseable, the first valid report on vps-godaddy showed **88 of 88 repos in `result: clone-failed` state**. The `sync-and-drift.sh` script runs as root via systemd timer, and root on the VPS has no SSH identity that authenticates to `git@github.com:marvelousempire/*`. Without read access, the script can't compare `origin/main` to `gitlab/main` for any repo — the entire drift-detection contract is dead in the water until this auth gap closes.

The operator wants the drift report to actually reflect drift, not "everything failed to clone."

## Outcome

_pending_ — fill in when status flips to `shipped`.

Target end state: `python3 -m json.tool /var/lib/yousirjuan/dual-push-drift-report.json` on vps-godaddy shows `failures: 0` (or a tiny number reflecting genuinely broken repos) and `entries` populated with real `origin` + `gitlab` SHAs for every repo in `tracked-repos.txt`.

## Approach options (operator picks before this leaves `planning`)

LEDGER-0024 reads from `git@github.com:marvelousempire/<repo>.git` over SSH. The fix lives somewhere on this matrix:

### Option A — Org-level deploy key

One read-only SSH key. Public half added to the **marvelousempire** GitHub org as a "deploy key" with access to **all repos**. Private half lives at `/etc/yousirjuan-sync/id_ed25519` on vps-godaddy with `0600` perms. `sync-and-drift.sh` learns to `GIT_SSH_COMMAND='ssh -i /etc/yousirjuan-sync/id_ed25519 -o IdentitiesOnly=yes'`.

- **Pros:** simplest, no GitHub Apps overhead, exactly one credential to rotate.
- **Cons:** GitHub doesn't actually have "org-wide deploy keys" — deploy keys are per-repo. So Option A is really "the same SSH key added as a deploy key on each repo." 88+ repos × one-key-add-per-repo = friction unless scripted via `gh api`. Doable but tedious.

### Option B — Machine user / service account

Create a GitHub user (e.g. `marvelousempire-sync-bot`) with read access to the org. Generate an SSH key for that user. The single key authenticates to every repo the user can see — no per-repo configuration.

- **Pros:** one key, one config, one place to revoke.
- **Cons:** machine users count against GitHub's seat licensing on paid plans; on the free plan they consume an org seat.

### Option C — Fine-grained personal access token (PAT)

Switch the script from SSH (`git@github.com:...`) to HTTPS (`https://<TOKEN>@github.com/marvelousempire/<repo>.git`). The token is org-scoped, read-only, with a 90-day or 1-year expiration.

- **Pros:** no SSH key management; can be locked to specific repos or all-org-repos; revocable from one GitHub page.
- **Cons:** rotation cadence is mandatory (max 1 year), the token is a bearer credential that anyone with `cat` access to the env file can use.

### Option D — GitHub App installation token

Create a GitHub App owned by marvelousempire, install it on the org with `contents: read` permission. The app generates short-lived installation tokens (1 hour). A small Python or shell helper trades the app's private key + installation ID for a token before each `git fetch`.

- **Pros:** short-lived tokens, fine-grained permission scope, no user seat consumed, audit log per app action.
- **Cons:** moving parts — needs the token-minting helper, the app's private key on disk, refresh logic. Overkill if simpler options suffice.

**Recommended starting point:** Option B (machine user) if there's a free seat available, else Option C (PAT). Option D is the right answer if this scales to other orgs later. Option A is the simplest but requires per-repo deploy-key creation that the script doesn't currently know how to do.

## Runbooks

(To be filled in once operator picks an option. Each runbook covers ONE step of the chosen path.)

- [01-pick-auth-strategy.md](runbooks/01-pick-auth-strategy.md) — decide A/B/C/D; document the call
- [02-generate-credential.md](runbooks/02-generate-credential.md) — create the key / PAT / GitHub App (varies by choice)
- [03-deploy-credential-to-vps.md](runbooks/03-deploy-credential-to-vps.md) — land the credential at `/etc/yousirjuan-sync/` with `0600` and `chown root:root`
- [04-teach-sync-and-drift-the-credential.md](runbooks/04-teach-sync-and-drift-the-credential.md) — `GIT_SSH_COMMAND` or HTTPS URL rewrite
- [05-verify-end-to-end.md](runbooks/05-verify-end-to-end.md) — `failures: 0` smoke check

## Playbooks

_no playbook because the auth strategy isn't picked yet. Once option A/B/C/D is chosen, the playbook lands as `playbooks/install-credential.sh` (idempotent) + a config patch to `sync-and-drift.sh`._

## Replay (zero-AI)

_pending — fills in once shipped._

## Verification

```bash
ssh vps-godaddy 'sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | \
  python3 -c "import sys,json; d=json.load(sys.stdin); print(f\"failures={d[chr(39)+\"failures\"+chr(39)]} / {d[chr(39)+\"total\"+chr(39)]}\")"'
```

Success criterion: `failures=0 / 88` (or close to it; a small handful of legitimately-archived repos is acceptable).

## Undo

```bash
# remove the credential
ssh vps-godaddy 'sudo rm -f /etc/yousirjuan-sync/id_ed25519 /etc/yousirjuan-sync/credentials'
# revert the script change
ssh vps-godaddy 'cd ~/Developer/yousirjuan && git checkout <pre-fix-sha> -- ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install'
```

On the GitHub side, revoke whichever credential was issued (deploy key / machine user / PAT / App).

## Notes

### Why this surfaced now

LEDGER-0024 v0.2.0 shipped with the auth gap latent — the JSON corruption bugs masked the underlying failures. v0.2.1 + v0.2.2 fixed the report so the operator could SEE that nothing was actually cloning. The pattern: **observability fixes reveal latent functional bugs.** This is the next one in line.

### Why root + systemd timer can't use the operator's keys

`sync-and-drift.sh` is installed at `/opt/yousirjuan-sync/sync-and-drift.sh` and triggered by `yousirjuan-dual-push-sync.timer`. The timer's `User=` is `root` (per the install.sh playbook). Root's `~/.ssh/` is empty by default on this VPS — and forwarding the operator's agent into a systemd-triggered process is not viable because systemd starts the process headless. So the credential MUST live on the VPS itself, owned and readable only by the user the timer runs as.

If the operator prefers, the timer could be re-configured to run as a dedicated `yousirjuan-sync` Unix user (created by install.sh), which would isolate the credential from root's environment. That's an Option B+ refinement.

### Org token scope concern

Whatever credential is chosen MUST be **read-only**. The script's job is to read both remotes and force-with-lease push WHEN DRIFT EXISTS — but the push target is gitlab, not github. The github credential never needs write access. If the picked credential ends up with write scope by default (PAT defaults can be sloppy), narrow it.
