# Changelog

All notable changes to **yousirjuan** ship here. Format follows the convention in [`.claude/rules/changelog-and-versioning.md`](../.claude/rules/changelog-and-versioning.md):

```
## [0.x.y] — YYYY-MM-DD HH:MM:SS Eastern · *short tagline*
```

Eastern time stamped to the second using `TZ=America/New_York date '+%Y-%m-%d %H:%M:%S'`. Newest entries first.

---

## [0.6.0] — 2026-06-02 10:48:05 Eastern · *Triple-threat edge architecture + LEDGER-0031 (Caddy-at-the-helm Phase 1)*

### Added
- `docs/edge-architecture-triple-threat.md` — target edge topology: **Caddy at the
  helm** (mTLS + wildcard DNS-01 + cassette routing, VPS + DGX), **nginx+WAF** as a
  Phase-3 public moat, **Traefik** as a Phase-2 dynamic-container dispatcher. Layered
  defense-in-depth; phased so each earns its keep.
- `ledger/LEDGER-0031-cassette-edge-mtls-wireguard/` — Phase 1 made real:
  `family-ca.sh` (EC P-256 private CA + per-device mTLS certs + revoke/CRL), the
  cassette-edge `Caddyfile` (wildcard DNS-01 via acme-dns + `client_auth` mTLS +
  Host-routing + default-deny), `acmedns.json.example`, and 4 runbooks (CA bootstrap,
  device-cert issue/install, reversible parallel-port Caddy cutover, GoDaddy DNS
  changes). Ledger index reconciled (0028–0031 rows added; Next number → 0032).
- Access model: ops/secrets → WireGuard-only (no public DNS); family apps → public
  but mTLS-gated; one `*.jailynmarvin.com` wildcard covers all.

## [0.5.0] — 2026-06-02 09:43:14 Eastern · *Cassette subdomain & edge architecture (Option A: edge anchor + CNAME per cassette)*

### Added
- `docs/cassette-subdomain-edge-architecture.md` — adopted infra design for
  per-cassette subdomains of the family TLD (`jailynmarvin.com`): a single `edge`
  A record holds the IP; every cassette is a **CNAME → edge** (auditable allowlist,
  no wildcard, per-host TLS, one-edit DGX failover). Includes the security tradeoff
  vs. wildcards, the mandatory **edge default-deny** vhost, the 3-step new-cassette
  ritual, and the reconciliation with the `one-tower-one-url` rule (Tower-embed is
  the default; subdomains are the operator-directed exception). Current live
  cassettes: nephew, search, bank, clinic, git → the VPS edge `72.167.151.251`.

## [0.4.0] — 2026-05-22 21:23:03 Eastern · *LEDGER-0025 — fine-grained PAT lands; sync-and-drift.sh now authenticates*

**Headline:** Option C selected. `sync-and-drift.sh` now reads `/etc/yousirjuan-sync/credentials` at start-of-run and rewrites the GitHub URL base from SSH to HTTPS-with-token. A new idempotent installer (`ledger/LEDGER-0025-.../playbooks/install-credential.sh`) handles the credential file with `0600 root:root` and runs a one-call API smoke test against `/orgs/marvelousempire`. Four runbooks (02–05) cover token generation, credential deploy, script behavior, and end-to-end verification.

### Added

- [`ledger/LEDGER-0025-.../playbooks/install-credential.sh`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/playbooks/install-credential.sh) — interactive / `--token` / `--from-stdin` modes; atomic file write; loose token-shape sanity; HTTP-code-aware smoke test (die clearly on 401/403/404).
- [`runbooks/02-generate-pat.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/02-generate-pat.md) — operator-only step (GitHub web UI). Scopes: `contents:read` + `metadata:read`. Cap: 366 days.
- [`runbooks/03-deploy-credential-to-vps.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/03-deploy-credential-to-vps.md) — interactive paste so the token never lands in shell history.
- [`runbooks/04-teach-sync-and-drift.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/04-teach-sync-and-drift.md) — documents the URL-rewrite mechanism and why token-in-URL beats credential-helper here.
- [`runbooks/05-verify-end-to-end.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/05-verify-end-to-end.md) — symptom→fix matrix + the canonical bright-line check (`failures < 5`).

### Changed

- [`ledger/LEDGER-0024-.../playbooks/sync-and-drift.sh`](../ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh) — reads `$CREDENTIALS_FILE` (default `/etc/yousirjuan-sync/credentials`); when `$GITHUB_TOKEN` is set, rewrites `GITHUB_URL_BASE` to `https://x-access-token:${GITHUB_TOKEN}@github.com/marvelousempire`. Falls back to SSH otherwise (preserves graceful-failure behavior if credentials are absent).
- [`ledger/LEDGER-0025-.../README.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/README.md) — status `planning → in-progress`; `## Decision (2026-05-22)` block records why Option C beat A/B/D today and where D fits in the roadmap.
- [`ledger/README.md`](../ledger/README.md) — LEDGER-0025 row updated to reflect Option C + the replay one-liner.

### Why Option C and not B / D

- **B (machine user):** GitHub now discourages machine users in favor of GitHub Apps.
- **D (GitHub App):** the right destination for multi-org future, but ~30 lines of token-minting helper + 1-hour refresh logic is more complexity than this single-org context needs today. Filed as the next ledger entry when multi-org is real.
- **C (PAT):** unblocks today, ~10 min from PR-merge to working drift detection. Annual rotation is a calendar event, not an emergency.

### What ships next

When the operator pastes the PAT into the installer on vps-godaddy and triggers a sync, `/var/lib/yousirjuan/dual-push-drift-report.json` should show `failures` drop from 88 → near 0. Status flips to `shipped` then.

## [0.3.0] — 2026-05-22 21:07:54 Eastern · *LEDGER-0025 — VPS deploy-key for marvelousempire (planning ticket)*

**Headline:** LEDGER-0024 v0.2.2 made the drift report parseable, and the first valid report on vps-godaddy showed `failures: 88 / 88` — the systemd timer's root user has no SSH identity that authenticates to `git@github.com:marvelousempire/*`. The drift detector can't read either remote, so no comparison happens. New ledger entry captures the gap, lays out four auth strategies (per-repo deploy keys / machine user / PAT / GitHub App), and parks at `planning` until the operator picks one.

### Added

- [`ledger/LEDGER-0025-vps-marvelousempire-deploy-key/README.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/README.md) — ticket with the four-option decision matrix, recommended default (machine user if single-org, GitHub App if multi-org coming), and the verification one-liner that closes the loop (`python3 -m json.tool` showing `failures: 0`).
- [`ledger/LEDGER-0025-.../runbooks/01-pick-auth-strategy.md`](../ledger/LEDGER-0025-vps-marvelousempire-deploy-key/runbooks/01-pick-auth-strategy.md) — first runbook, the decision step.

### Changed

- [`ledger/README.md`](../ledger/README.md) — next number bumped `0025 → 0026`; new index row for LEDGER-0025 with status `planning`.

### Why this is here

Per the `version-bump-and-changelog` rule v2: every ledger entry is a logged operator-visible event. Bump + CHANGELOG + tag + Release.

### What ships next

When the operator picks A/B/C/D in `runbooks/01-pick-auth-strategy.md`, the implementation lands as a follow-up minor bump with the playbook + verification.

## [0.2.2] — 2026-05-22 20:59:14 Eastern · *fix LEDGER-0024 drift report JSON (second bug)*

**Headline:** v0.2.1 fixed the embedded-newline bug in the count fields but the JSON was still malformed because every clone-failure logged an `echo "  ✗ clone failed: <repo>"` on stdout, which the parallel `xargs ... >>"$results_tmp"` captured into the entries array between the JSON objects.

The first deploy on vps-godaddy surfaced this — 88 clone failures (likely a separate SSH-key issue), each emitting a non-JSON line that broke the parser at `line 7 column 7 (char 118)`.

### Fixed

- `ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh` — clone-failure echo now redirects to stderr (`>&2`). The parent script's `exec >>"$LOG" 2>&1` still catches it into the log file, but the xargs subshell's stdout redirect (`>>"$results_tmp"`) no longer sees it. Only the canonical `printf '  {...}\n'` reaches the results file.

### Side benefit

- The `total` count is now accurate. Before this fix, each clone-failed repo wrote 2 lines (echo + JSON) and `wc -l` counted both, doubling the total.

### Verification

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git pull --ff-only && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install && \
  sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  echo --- && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -40'
```

### Known follow-up (not this PR)

88 clone failures on vps-godaddy point to an SSH-key / deploy-key gap on the marvelousempire org. That's a separate ledger item — this PR only makes the report parseable so the operator can SEE what's failing.

## [0.2.1] — 2026-05-22 20:39:17 Eastern · *fix LEDGER-0024 drift report JSON*

**Headline:** the dual-push drift report was emitting malformed JSON whenever the drift or failure count was zero (the common case). `python3 -m json.tool` failed with `Expecting ',' delimiter: line 5 column 1 (char 78)` and the operator-facing report was unparseable.

### Fixed

- `ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/sync-and-drift.sh` — replaced `|| echo 0` with `|| true` on the two `grep -c ... || ...` guards. `grep -c` always writes the count to stdout (including `0` for zero matches) and exits non-zero only when zero matches; the old guard appended a *second* `0\n` after the first, producing a literal newline inside the JSON number. `|| true` silences the non-zero exit without contaminating stdout.

### Verification

```bash
# locally:
touch /tmp/empty.txt
NEW="$(grep -cE 'never' /tmp/empty.txt || true)"
echo "[${NEW}]"   # → [0]   (one character, not "0\n0")

# on vps-godaddy after pull + re-install:
sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool
```

The second command now parses cleanly.

### Deploy path

```bash
ssh vps-godaddy 'cd ~/Developer/yousirjuan && \
  git pull --ff-only && \
  sudo bash ledger/LEDGER-0024-dual-push-drift-prevention/playbooks/install.sh install && \
  sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  echo --- && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -40'
```

`install.sh install` is idempotent — it copies the fixed script into `/opt/yousirjuan-sync/` and the systemd timer picks it up on the next 5-min tick (or run it manually as shown).

## [0.2.0] — 2026-05-20 01:36:41 Eastern · *self-codifying ledger + workflow-debugger agent*

**Headline:** yousirjuan grew a permanent **knowledge layer** today — a `/ledger/` system where every non-trivial task lands as ticket + runbook + executable playbook, so the same task doesn't need an AI the second time. First two entries shipped: the iMac MCP development stack (the embryo that proved the pattern), and a `workflow-debugger` specialist agent for YAML/Bash/JS/Python/Excel pipeline bugs.

### Added

- **`/ledger/` system** — top-level home for replayable task knowledge ([`ledger/README.md`](../ledger/README.md), [`ledger/_template/`](../ledger/_template/)). Index + format-choice guide + helper-function snippet + triggers table. Soft rule: [`.claude/rules/ledger-discipline.md`](../.claude/rules/ledger-discipline.md).
- **LEDGER-0001** — iMac MCP development stack (VS Code + Cline + Ollama-as-LaunchAgent, all reproducible via `make install` from [`ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile`](../ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile)). 5 runbooks, 1 Makefile, 1 shell playbook (`install.sh` for environments without `make`), 1 launchd plist. Resolves [`PAIN-0006`](../pain-journal/PAIN-0006-ollama-app-incompatible.md), [`PAIN-0007`](../pain-journal/PAIN-0007-code-cli-not-on-path.md), [`PAIN-0008`](../pain-journal/PAIN-0008-copilot-paywall.md), [`PAIN-0009`](../pain-journal/PAIN-0009-mcp-config-fragmented.md), [`PAIN-0010`](../pain-journal/PAIN-0010-intel-cpu-no-gpu.md).
- **LEDGER-0002** — `workflow-debugger` Claude Code agent at [`.claude/agents/workflow-debugger.md`](../.claude/agents/workflow-debugger.md). Specialist for YAML/Bash/JavaScript/Python/Excel pipeline failures. Encodes symptom-first diagnostic loop, willingness to discard wrong hypotheses fast, gotcha catalog per language, and verification ritual. Project-scoped by default; user-scope install via [`ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh`](../ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh).
- **Auto-sync hook** — `PostToolUse` hook in [`.claude/settings.json`](../.claude/settings.json) automatically re-syncs the workflow-debugger agent from project scope to user scope whenever the project-scope file is edited. Controllable via the `/hooks` slash-command UI in Claude Code.
- **CLI snippet formatting rule** — [`.claude/rules/cli-snippet-formatting.md`](../.claude/rules/cli-snippet-formatting.md). Every agent in this repo formats shell snippets as one copy-pasteable block with `\` continuations and `&&` chaining; never split across multiple fenced code blocks.

### Changed

- **HANDOFF.md** §7 — appended Day 4 (2026-05-19) entry covering the MCP stack work, with pointers into the new ledger. Frontmatter `Latest update:` line refreshed.
- **CI contract enforcement workflow** loosened — explicit allowlist for product-doc files where Associate Agent / interface UX references are intentional (CLAUDE.md, README.md, docs/marketing/**, etc.). The workflow had been failing on every main push since it was added; now passes.

### Fixed

- **`release-intel-mac.yml`** workflow YAML parse error. Lines 93–107 were at column 1 inside a `run: |` literal block whose first content line was at 10-space indent. YAML was terminating the block at the first under-indented line and trying to parse `One-liner:` as a sibling key. Rewrote the "Publish to marvelousempire/yousirjuan-ai releases" step to use `cat <<EOF | sed 's/^          //' > /tmp/release-notes.md` so heredoc content satisfies YAML indentation but renders left-aligned. Workflow now correctly fires only on `v*.*.*` tag pushes + `workflow_dispatch`. (Em-dash hypothesis in PR #9 was a red herring — see [`Issue-Log.md`](Issue-Log.md).)

### Infrastructure / repo plumbing

- Migrated `docs/sessions/2026-05-19-mcp-setup/` → `ledger/LEDGER-0001-imac-mcp-setup/` and reshaped to the ledger schema (`artifacts/Makefile` → `playbooks/Makefile`, new ticket README with YAML frontmatter, etc.). All cross-file links updated.
- Added `.claude/agents/` directory (new project-scoped agent home).
- Added `ledger/_template/` skeleton for new ledger entries.

### Ships behind

- `bishop` / `bishop-factory` repo consolidation (the two are byte-identical duplicates; archive `bishop-factory`, keep `bishop` as canonical). Documented in plan file at [`~/.claude/plans/what-is-the-best-curious-willow.md`](~/.claude/plans/what-is-the-best-curious-willow.md) §"Part 2"; not shipped today.
- CI hardening for the ledger pattern — a check that fails PRs touching `runbooks/**` or `playbooks/**` outside a `LEDGER-NNNN/` folder. Wait until ~5 real ledger entries exist before adding.

### PRs

[#4](https://github.com/marvelousempire/yousirjuan/pull/4), [#5](https://github.com/marvelousempire/yousirjuan/pull/5), [#7](https://github.com/marvelousempire/yousirjuan/pull/7), [#8](https://github.com/marvelousempire/yousirjuan/pull/8), [#9](https://github.com/marvelousempire/yousirjuan/pull/9) (em-dash red herring — see Issue-Log), [#10](https://github.com/marvelousempire/yousirjuan/pull/10) (real workflow fix), [#11](https://github.com/marvelousempire/yousirjuan/pull/11), [#12](https://github.com/marvelousempire/yousirjuan/pull/12), and the chore PR that ships this changelog.

### Version bumps

Platform monorepo (Node packages, all in lockstep): root [`package.json`](../package.json), [`apps/admin/package.json`](../apps/admin/package.json), [`apps/yousirjuan-web/package.json`](../apps/yousirjuan-web/package.json), [`services/homekit-bridge/package.json`](../services/homekit-bridge/package.json) — all 0.1.0 → 0.2.0.

**`apps/yousirjuan-ios` is NOT bumped** and intentionally runs on a separate cycle. The iOS app is at `CFBundleShortVersionString = 1.0` / `CFBundleVersion = 1` (see [`Info.plist`](../apps/yousirjuan-ios/Sources/Info.plist)); iOS marketing versions follow App Store review cycles, not the platform's `0.x` semver. Earlier I claimed there was "no discoverable version surface" — that was wrong; the surface exists, it's just on a different cycle.

---

## [0.1.0] — baseline (pre-2026-05-20)

Initial yousirjuan platform: README, HANDOFF.md, REPOS-CONTRACT.md, CI-CONTRACT-GUIDE.md, CLAUDE.md (Claude Code agent routing guide), `installers/intel-mac/install.sh`, `docker-compose.yml` with the stack (Ollama, Open WebUI, Qdrant, Postgres, Redis, Kokoro, nginx), `apps/yousirjuan-web/` + `apps/admin/` + `apps/yousirjuan-ios/`, `vendor/ai-skills-library/` submodule wiring, `pain-journal/` (entries PAIN-0001 through PAIN-0005), VPS deployment scripts, GitHub Actions workflows, contract-enforcement CI.

Reconstructed retroactively from git history — no per-PR changelog was maintained pre-0.2.0. Anything earlier than today's `0.2.0 entry` lives in git log and HANDOFF.md §7's session timeline (Days 1–3, 2026-04-24 through 2026-04-26).
