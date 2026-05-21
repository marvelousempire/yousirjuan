---
ledgerId: LEDGER-0022
title: Cross-repo contract checks — private parent ↔ public framework (Contribution Network)
status: shipped
opened: 2026-05-21
closed: 2026-05-21
related-tickets: [LEDGER-0005, LEDGER-0021]
triggers:
  - gitlab-ci:contract-checks job on every push / MR / schedule
  - manual-cli:`make check` in the private parent
---

# LEDGER-0022 — Cross-repo contract checks

## Ask

Operator 2026-05-21 quoted back the LEDGER-0021 open follow-up: *"CI cross-repo contract checks — future PR could add a CI job in the private parent that runs 'does this private deploy still align with the public framework's contracts?'"*

Translation: now that the private parent (LEDGER-0021) submodules the public framework, write the CI checks that catch when the parent drifts away from contracts the framework expects.

## Outcome

Shipped in `marvelousempire/contribution-network-private` PR #1 (merged 2026-05-21):

- `Makefile` with `make check` target — runs all 4 contract checks
- `.gitlab-ci.yml` running the same checks in CI on every push / MR / schedule
- 4 individual check scripts under `scripts/`

Both halves run the same checks — local pre-push and CI are identical.

## The 4 checks

| Check | What it catches |
|---|---|
| **check-submodule** | Submodule not initialized; parent pointer ≠ submodule HEAD (orphan bump); dirty working tree; HEAD not reachable from origin (private-only commit being silently committed to parent) |
| **check-framework-structure** | Framework's required dirs/files missing (README, ARCHITECTURE, CN-SOPS, GOVERNANCE, PRINCIPLES, cartridges, consoles, contributions, registry, scripts, templates) |
| **check-secrets** | High-signal secret regex patrol on git-tracked files: AWS keys, OpenAI/Anthropic/xAI tokens, GitHub PATs, private keys, our own watchdog/VPS-agent tokens, GoDaddy API creds |
| **check-version-pin** | Submodule SHA must be in `scripts/known-good-pins.txt` (operator-maintained allowlist). Auto-seeds on first run. On unknown pin: clear error + paste-ready command to bless |

## Why GitLab CI (not GitHub Actions)

Two reasons:

1. **LEDGER-0005** established GitLab as the sovereign source-of-truth. CI for first-class platform repos lives there.
2. **yousirjuan PR #23** disabled all GitHub Actions in yousirjuan. New CI shouldn't reintroduce that pattern.

## How a normal bump flow looks now

```bash
cd ~/Developer/contribution-network-private/contribution-network/
git fetch && git checkout origin/main           # pull latest framework

cd ..
git add contribution-network                    # parent records new pointer

# Add the new SHA to the allowlist OR the check fails
echo "$(cd contribution-network && git rev-parse HEAD)  # $(date -u +%Y-%m-%d) — <reason>" \
  >> scripts/known-good-pins.txt
git add scripts/known-good-pins.txt

make check                                       # verify before push
git commit -m "bump: framework → $(cd contribution-network && git rev-parse --short HEAD)"
bash /Users/averygoodman/Developer/yousirjuan/tools/git-dual-push.sh main
```

GitLab CI re-runs `make check` on the push, fails loudly if anything drifted.

## How a deliberate-framework-change flow looks

```bash
# 1. Make the framework change in the public repo
cd ~/Developer/ContributionNetwork    # or via the submodule path
# (edit, commit, push to public)

# 2. Bump the private parent to the new framework commit
cd ~/Developer/contribution-network-private/contribution-network/
git pull origin main
cd ..
git add contribution-network

# 3. Bless the new pin
echo "$(cd contribution-network && git rev-parse HEAD)  # $(date -u +%Y-%m-%d) — added new cartridge X to framework" \
  >> scripts/known-good-pins.txt

# 4. Verify the framework change didn't break private structure expectations
make check

# 5. Commit + push
git add scripts/known-good-pins.txt
git commit -m "bump: framework with new cartridge X"
bash /Users/averygoodman/Developer/yousirjuan/tools/git-dual-push.sh main
```

If the framework change removed a file the private parent depended on, `check-framework-structure` fails — operator knows immediately, before pushing.

## Locally

`make check` is the operator's pre-push button. Five seconds. Same logic as CI; finds issues before they hit the pipeline.

## Adding a new check

Add `scripts/check-<name>.sh`, source the `BLUE/GREEN/RED/NC` color vars, use `ok/bad` helpers, exit non-zero on failure. Then add to the `check:` target in Makefile.

Pattern is intentionally lightweight — bash + grep + git, no Python deps beyond stdlib, no node, no docker. Runs on alpine:3.20 in CI under 30s.

## Cross-references

- LEDGER-0021 — private parent + public submodule pattern (the foundation)
- LEDGER-0005 — GitLab as sovereign source-of-truth (why CI lives there)
- yousirjuan PR #23 — GitHub Actions elimination (why CI doesn't live in GH)
- Rule 14 (Dual-Push) — every push to this repo dual-targets both forges
- `marvelousempire/contribution-network-private` PR #1 — the actual implementation

## Open follow-ups (not blocking)

- **Schema validation** — once the framework defines explicit JSON/YAML schemas for cartridges/contributions, add `check-schemas.sh` that validates any private deploy content against them
- **CI on schedule** — add a nightly schedule that runs `make check` even when no push has happened (catches framework changes published upstream that affect the pinned SHA's contracts)
- **Apply same pattern to other private↔public pairs** — when the next pair emerges, copy the Makefile + scripts/ + .gitlab-ci.yml as the starter
