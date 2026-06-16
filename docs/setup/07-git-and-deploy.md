# Chapter 7 — Git, Forge & Deploy Discipline

**Public-safe:** workflow and rules only. No hostnames, keys, or paths with usernames.

> **Why Gitea vs GitLab:** [18-wireguard-matrix-nas-gitea-why.md](./18-wireguard-matrix-nas-gitea-why.md)

---

## Chapter intents

| Intent | Why |
|---|---|
| **Gitea = daily forge** | Direct push, no PR gate — fast inner loop |
| **GitHub = mirror + PRs** | Branch protection, collaboration, offsite backup |
| **SSH only** | No PAT expiry — macOS keychain |
| **Explicit-path stage** | Never `git add -A` — monorepo drift guard |
| **CLI-first ship** | Local verify + laptop deploy — not GitHub Actions billing |
| **Plans are immutable** | Append-only decision history |

---

## Source-of-truth hierarchy

| Layer | Source of truth |
|---|---|
| Infrastructure intent | **yousirjuan** `ledger/` + `docs/setup/` |
| Runtime composes | **nephew** `deploy/dgx/`, `containers/`, `docker-compose.dgx.yml` |
| Product behaviour | **nephew** manifests + cassette framework |
| Shared skills/rules | **ai-skills-library** (propagate to consumers) |
| Live box state | **Git** — redeploy from tracked files, not manual drift |

---

## Self-hosted git forge

| Component | Location |
|---|---|
| Gitea web + SSH | DGX container |
| Git object storage | NAS RAID mount |
| Gitea database | DGX local (not on NFS) |
| GitHub | Offsite mirror of forge pushes |

**Workflow:**

- Day-to-day: `git push` to forge remote — no PR gate on forge `main`
- Release / collaboration: PR to GitHub `main` (branch protection, no force-push)
- Forge self-heals on boot via systemd unit + git-tracked compose

---

## SSH git (token-free)

- All `origin` remotes use `git@github.com:org/repo.git`
- macOS keychain holds key passphrases (`UseKeychain yes` in SSH config)
- Forge alias uses same key material with host block for the DGX forge

Forbidden: embedding PATs in remotes for routine push.

---

## SSO vs git SSH (cassette standard)

| Surface | Auth | Never use for git CLI |
|---|---|---|
| **Gitea web UI** (`:3300`) | Nephew OIDC / family SSO | — |
| **Pockit / cassette doors** | `nephew_session` cookie / mTLS | — |
| **`git push` / `git pull`** | **SSH keys** in macOS keychain | OAuth, PAT, browser SSO |

**Web SSO does not authenticate `git push`.** That is intentional — cassette deploy discipline is SSH-only (clean deploy = `git pull`, not scp).

One-time Mac setup:

```bash
bash scripts/setup-cassette-git-ssh.sh
bash scripts/setup-forge-remotes.sh
```

If GitHub org uses **SAML SSO**: after adding your SSH public key at GitHub → Settings → SSH keys, click **Configure SSO** → **Authorize** for `marvelousempire`. Without that step, `git@github.com` returns `Permission denied` even when the key exists.

**Gitea master works without GitHub SSH:** `git push gitea main` or `make forge-push` (push-mirror syncs GitHub when configured).

---

## Dual-remote sync guardrails

- Never force-push `main` on GitHub
- Sync scripts refuse push when local is behind remote (freshness guard)
- GitHub branch protection: no force-push, no deletion, enforce admins

Documented incident: stale checkout force-push reverted a merge — prevention is branch protection + freshness guard in `scripts/git-push-all.sh`.

---

## Ship cycle (Nephew / aligned repos)

Pipeline stages — name the stage when reporting status:

```text
In working tree → Committed → Pushed → PR'd → Merged → Deployed → Live
```

| Step | Discipline |
|---|---|
| Stage | Explicit paths only — never `git add -A` |
| Verify | `make nephew-verify` or `nephew ship verify` before push |
| Commit | Conventional message; CHANGELOG in same PR |
| PR | `gh pr create` — never invisible pushed branches |
| Merge | Squash from **outside** the worktree being deleted |
| Deploy | `make deploy-*` from operator Mac — not GitHub Actions |
| Live | Curl apex or smoke script confirms version |

CLI-first: no billing GitHub Actions for deploy gates.

---

## DGX deploy

- SSH to compute node → pull nephew → compose up from tracked files
- Systemd units for long-running stacks (Gitea, corpus reindex timer, fleet refresh)
- `make family` on DGX starts full family stack (from Mac LAN browser use compute node's LAN hostname — see mac-dgx rule in nephew)

IaC entry: `marvelousempire/nephew` → `infra/README.md`, `deploy/dgx/README.md`

---

## VPS deploy

- Family apex static assets sync to VPS nginx docroot
- Clinic repo deploys separately
- Edge proxies reach DGX services over WireGuard — not public LAN ports on home

Scripts: `deploy-nephew-wp.sh`, `wp-mirror-full-ready.sh`, etc. in nephew `scripts/`

---

## Secret hygiene (all repos)

Three layers:

1. `.gitignore` patterns for env, keys, certs, WireGuard configs  
2. `.githooks/pre-commit` — refuse secret-shaped staged files + gitleaks  
3. `.githooks/pre-push` — gitleaks over push range  

Run `make hooks` on fresh clone. Every secret config has a `.example` twin with `CHANGEME`.

---

## Plans folder convention

Substantive changes get an append-only plan:

- **nephew:** `plans/NNNN-snake-case-title.md`
- **yousirjuan:** `plans/` (same discipline)

Immutable history — supersede with new plan, never rewrite old.

---

## Verification gates

Before merge to main:

- Skill count / frontmatter lint (where applicable)
- Canonical door URL copy check (`check-canonical-door-url-copy.mjs`)
- Script syntax, link sanity, compose label parse
- Cassette assembly line: `make cassette-line CHECK=<id>`

Standard: `marvelousempire/nephew` → `docs/standards/verification-gates.md`

---

## Related

- [02-network-security.md](./02-network-security.md) — mesh access for deploy
- [04-repo-ecosystem.md](./04-repo-ecosystem.md) — repo boundaries
- [08-daily-operator-workflows.md](./08-daily-operator-workflows.md) — operator commands
- [`CI-CONTRACT-GUIDE.md`](../../CI-CONTRACT-GUIDE.md) — contract enforcement
