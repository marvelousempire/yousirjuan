---
ledgerId: LEDGER-0005
title: GitLab CE on the VPS as sovereign source-of-truth; GitHub becomes a push-mirror
status: planning
opened: 2026-05-20
closed: null
related-pains: []
related-tickets: [LEDGER-0004]
triggers:
  - manual-cli: `bash ledger/LEDGER-0005-gitlab-as-source-of-truth/playbooks/configure-and-migrate.sh <action>`
---

# LEDGER-0005 — GitLab CE as sovereign source-of-truth

## Ask

> "maybe we can push them to the Gitlab server on my VPS and then sync with GitHub? We can zip the files up to the VPS then update them on the server and then push to GitHub from our Gitlab?"

(Originally proposed as a workaround for the cross-org GitHub PR ceremony during the LEDGER-0004 rollout — see [`Notes` below](#notes) for why we explicitly decoupled the two decisions.)

## Outcome (planned, not shipped)

Migrate the development workflow from GitHub-as-source-of-truth to **GitLab CE on the VPS as source-of-truth, with GitHub serving as a downstream push-mirror.** Daily commits, MRs, CI, and merges happen on `gitlab.yousirjuan.ai`; GitHub stays in sync as a read-mostly mirror so public collaboration / discovery still works.

This aligns with the yousirjuan ethos as documented in [`governance/gitlab-ce-stack.md`](../../governance/gitlab-ce-stack.md) and [`governance/sovereign-devops-stack.md`](../../governance/sovereign-devops-stack.md): self-hosted, sovereign, operator-owned operational backbone.

## Recon findings (2026-05-20)

A direct SSH inspection of `vps-godaddy` produced these facts. They change the work-scope from "deploy GitLab" to "configure GitLab integration" — the heavy lifting is already done.

### GitLab is already deployed and running

```
$ docker ps
gitlab          Up 2 days (healthy)   80/tcp, 443/tcp, 127.0.0.1:8929->8929/tcp, 0.0.0.0:2424->22/tcp
gitlab-runner   Up 2 days
```

- Web UI on `127.0.0.1:8929` (localhost only — needs nginx vhost for public access).
- SSH for git operations on `0.0.0.0:2424` (public; ready to use).
- Runner is registered and running.
- GitLab process uses ~2.4 GB RAM (~30% of VPS); steady-state load is negligible (1.5% CPU).

### VPS load average looked alarming but isn't GitLab's fault

Initial uptime reported `load average: 10.18, 10.52, 10.42` on a 4-CPU VPS. Investigation showed the culprit is **Cursor's remote-server file indexer** running two `rg --files` processes consuming 162% + 161% CPU between them. Plus a Cursor extension host at 14.8% CPU + 2 GB RAM. Plus `kswapd0` at 18% from swap-thrashing on the Cursor memory pressure.

**GitLab itself is using 1.5% CPU and 2.4 GB RAM.** It's not the load source.

The Cursor situation is a separate problem (likely needs the file-watcher to exclude `node_modules`, `.git`, and the GitLab data dir; or to detach the Cursor remote-server entirely). It's documented here only to explain why my initial caution about "VPS is overloaded, don't add work" turned out to be wrong: the capacity headroom for GitLab work is fine.

### Existing nginx vhosts (for reference)

```
clinic.yousirjuan.ai
default
hello.yousirjuan.ai
massillon-legal
nephew.yousirjuan.ai
readyplay-admin / readyplay-api / readyplay-marketing / readyplay-me
thebriefcase.app
```

A new `gitlab.yousirjuan.ai` vhost slots into this convention.

## Implementation plan

Three phases, each independently shippable.

### Phase 1 — Make GitLab publicly accessible

1. Add nginx vhost `gitlab.yousirjuan.ai` → proxies to `127.0.0.1:8929` (HTTP) and handles WebSocket upgrades for GitLab's live features.
2. DNS: add `A gitlab.yousirjuan.ai → 72.167.151.251`.
3. Provision Let's Encrypt cert via certbot (same flow as the other vhosts).
4. Configure GitLab's `external_url` to `https://gitlab.yousirjuan.ai` so it generates correct links + supports webhooks.
5. **Test:** browse to the URL, log in (or create root password if first-run), see the empty dashboard.

This phase has no impact on existing services. nginx reload is the only state change.

### Phase 2 — Migrate `yousirjuan` as the first repo

1. Create the project on GitLab CE (UI or `glab` CLI).
2. Mirror current `marvelousempire/yousirjuan` into GitLab (one-time clone-and-push).
3. Configure **push-mirror to GitHub** in GitLab's project settings:
   - URL: `https://github.com/marvelousempire/yousirjuan.git`
   - Auth: GitHub PAT with `repo` scope (operator generates it)
   - Trigger: on every push (default).
4. Test the flow:
   - Push a trivial commit on GitLab (e.g., update `docs/CHANGELOG.md`).
   - Watch GitLab's mirror job complete.
   - Verify the commit appears on `github.com/marvelousempire/yousirjuan/commits/main` within a minute.
5. Reverse direction (NOT in this phase): GitHub→GitLab pull-mirror would let GitHub contributors still work. For now, GitHub is write-blocked except via GitLab. Operator decides if that's right.

If Phase 2 succeeds for yousirjuan, the pattern is proven and Phase 3 just repeats it.

### Phase 3 — Migrate the remaining ~46 repos

Idempotent batch script under [`playbooks/configure-and-migrate.sh`](playbooks/configure-and-migrate.sh) (to be written) that:

1. Reads the list of marvelousempire repos (same `gh repo list` filter as LEDGER-0004).
2. For each, creates the GitLab project, mirrors the current GitHub state, configures push-mirror back to GitHub.
3. Reports per-repo status: ✓ migrated, ⚠ partial, ✗ failed.

Idempotent: re-running on a repo already migrated is a no-op.

## Critical files (to be created)

- `ledger/LEDGER-0005-gitlab-as-source-of-truth/README.md` — this ticket (created)
- `ledger/LEDGER-0005-gitlab-as-source-of-truth/runbooks/01-phase-1-nginx-vhost.md` — concrete nginx config + certbot steps (TODO)
- `ledger/LEDGER-0005-gitlab-as-source-of-truth/runbooks/02-phase-2-migrate-yousirjuan.md` — first-repo migration (TODO)
- `ledger/LEDGER-0005-gitlab-as-source-of-truth/runbooks/03-phase-3-fleet-migration.md` — batch script usage (TODO)
- `ledger/LEDGER-0005-gitlab-as-source-of-truth/playbooks/configure-and-migrate.sh` — fleet migration script (TODO)
- `ledger/LEDGER-0005-gitlab-as-source-of-truth/artifacts/nginx-gitlab-vhost.conf` — canonical nginx vhost template (TODO)

This PR adds only the ticket. The runbooks + playbooks come in follow-up PRs as each phase is shipped.

## Why decoupled from LEDGER-0004's rollout

The operator initially proposed using the GitLab path as a workaround for the cross-org GitHub PR ceremony that was blocking LEDGER-0004's 47-repo rollout. I pushed back: routing the same 47-repo writes through GitLab mirror to bypass the GitHub-PR classifier guard would be the very anti-pattern the [`contracts-and-prudence.md`](../../.claude/rules/contracts-and-prudence.md) rule forbids ("don't suppress an error to make a symptom go away without diagnosing the cause" / "don't work around a safety check we don't understand").

GitLab-as-source-of-truth is genuinely a good architectural decision for *other* reasons (sovereignty, control, the existing governance docs already say so). It's just not the right tactical lever for that one specific rollout. The two decisions are independent and this entry treats them as such.

## Verification (per phase)

- **Phase 1 done when:** `curl -I https://gitlab.yousirjuan.ai/users/sign_in` returns 200; valid Let's Encrypt cert; GitLab admin can SSH at `git@gitlab.yousirjuan.ai:2424`.
- **Phase 2 done when:** a commit on GitLab's yousirjuan repo appears on GitHub's mirror within 60s; both copies have identical SHA at HEAD.
- **Phase 3 done when:** `bash playbooks/configure-and-migrate.sh status` reports all ~47 repos as ✓ migrated.

## Undo

- **Phase 1:** remove the nginx vhost + DNS record + cert; GitLab returns to localhost-only state. No data loss.
- **Phase 2:** delete the GitLab project for yousirjuan. GitHub stays untouched.
- **Phase 3:** delete the GitLab projects (or use the playbook's `undo` action).

## Notes

- **The Cursor remote-server load issue** documented in the recon findings is its own problem; it deserves a separate ledger entry. Out of scope here.
- **Authentication for GitLab.** Initial deploy used a root password set in the GitLab Omnibus config. Migration to SSO / OIDC is a follow-up; LDAP or Keycloak both work with GitLab CE. Not blocking the current work.
- **Backup strategy** for GitLab needs to be designed before Phase 3. Losing the GitLab DB once it's the source-of-truth = losing all the post-migration commits. Likely a daily `gitlab-rake gitlab:backup:create` to off-VPS storage (Tailscale-only backup target on a different host).
- **The fail2ban / iptables-public-lockdown.sh** configuration on the VPS may need adjustment for GitLab's port 2424 (SSH for git). Check before Phase 1 ships.
