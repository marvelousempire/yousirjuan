# Chapter 23 — Forge Sync Automation (Gitea Master ↔ GitHub Mirror)

**Public-safe:** how git sync runs without manual steps or GitHub Actions billing.

---

## Chapter intents

| Intent | Why |
|---|---|
| **Gitea = master** | Sovereign forge on Family Office hardware |
| **GitHub = mirror lane** | Enterprise agents without VPN push here |
| **Automatic reconcile** | Timer fixes GitHub-ahead drift within 5 minutes |
| **Push mirror on commit** | Gitea → GitHub without manual `ssh` mirror push |
| **Gitea Actions CI** | `.gitea/workflows/` replaces billable GitHub Actions |
| **No duplicate repos** | Use **`marvelousempire/yousirjuan`** only — not `avery/yousirjuan` |

---

## The loop (hands-free)

```text
Enterprise agents ──push/PR──► GitHub main
                                    │
                    forge-sync timer (every 5 min)
                    OR: make forge-sync
                                    │
                                    ▼
              Gitea marvelousempire/yousirjuan  ◄── MASTER
                                    │
                    push-mirror (sync_on_commit)
                                    │
                                    ▼
                              GitHub main (backup)

Operator / Nephew on Mac:
  make forge-push  →  verify + push gitea  →  mirror updates GitHub
```

---

## Remotes (one-time per clone)

```bash
bash scripts/setup-forge-remotes.sh
```

| Remote | URL | Role |
|---|---|---|
| **`gitea`** | `git@gitea-dgx:marvelousempire/<repo>.git` | **Master** — push here |
| **`origin`** | `git@github.com:marvelousempire/<repo>.git` | Mirror / enterprise lane |
| **`gitlab`** | Same as gitea (legacy alias) | Family Office convention |

---

## Make targets

| Command | When |
|---|---|
| `make verify` | Local gate — setup index, required scripts |
| `make forge-push` | **After edits** — verify + push Gitea + GitHub |
| `make forge-sync` | One repo reconcile (GitHub ahead → fast-forward Gitea) |
| `make forge-sync-core` | Core public repos only (timer default) |
| `make forge-sync-all` | Full list via `FORGE_SYNC_LIST` (needs GitHub SSH/PAT) |
| `make forge-status` | Print SHAs + push-mirror health |

---

## Gitea Actions (CI on your metal)

Workflows live in **`.gitea/workflows/`** (not `.github/workflows/`).

| Workflow | Trigger | Runs |
|---|---|---|
| `verify.yml` | push/PR to `main` | `node scripts/yousirjuan-verify.mjs` + `npm test` |

**Requires:** Gitea Actions enabled + `act_runner` on DGX.

```bash
# On nephew-spark (once):
bash scripts/gitea-enable-actions.sh
# Gitea UI → Actions → Runners → Create token
cd deploy/gitea && GITEA_RUNNER_TOKEN=<token> docker compose -f act-runner-compose.yml up -d
```

Runner label: `self-hosted` (matches workflow `runs-on`).

---

## Background timer (GitHub → Gitea)

Install on DGX (user systemd):

```bash
bash scripts/install-dgx-forge-sync-timer.sh
```

Install on Mac (LaunchAgent):

```bash
bash scripts/install-mac-forge-sync-timer.sh
```

Runs `scripts/forge-sync-core.sh` every **5 minutes** — catches enterprise agent pushes to GitHub without you in the loop.

**DGX** uses `scripts/forge-pull-on-gitea-core.sh` (HTTPS into Gitea bare repos — no Mac GitHub SSH).

**Mac** does not need GitHub SSH for status/sync on **public** repos — `forge-status` and `forge-sync` fall back to HTTPS.

Log: `~/.local/share/yousirjuan/forge-sync.log` (Mac) · `~/.local/share/yousirjuan/forge-pull.log` (DGX pull)

---

## Push mirror (Gitea → GitHub)

Configured in Gitea for **`marvelousempire/yousirjuan`** with `sync_on_commit`.

Check health:

```bash
make forge-status
```

If `last_error` shows force-push rejected — never force-push GitHub `main`; use fast-forward only.

---

## Deprecated: `avery/yousirjuan`

A duplicate Gitea repo existed under user **`avery`**. It bypassed push-mirror automation.

**Use only:** `marvelousempire/yousirjuan` on Gitea.

---

## VPS LEDGER-0024 (optional second net)

`ledger/LEDGER-0024-dual-push-drift-prevention/` installs a VPS timer when Gitea is fronted at `git.jailynmarvin.com:2424`. The DGX user timer above is the **primary** net for Family Office hardware.

---

## Agent rules

1. Enterprise agents: PR to **GitHub `main`** — timer syncs to Gitea within 5 min.
2. Operator/Nephew: **`make forge-push`** — immediate master + mirror.
3. Never cite `avery/yousirjuan` as forge remote.
4. Never wait on GitHub Actions — Gitea Actions or `make verify` locally.

---

## Related

- [07-git-and-deploy.md](./07-git-and-deploy.md)
- [18-wireguard-matrix-nas-gitea-why.md](./18-wireguard-matrix-nas-gitea-why.md)
- [22-doc-era-reconciliation.md](./22-doc-era-reconciliation.md)
- `ledger/LEDGER-0024-dual-push-drift-prevention/README.md`
