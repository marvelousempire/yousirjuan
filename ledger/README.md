# Ledger — codified runbooks & playbooks

The ledger is yousirjuan's **operational memory**. Every meaningful task an agent (or human) does in this repo lands here as one entry containing three artifacts:

| Artifact | What it is | Lives at |
|---|---|---|
| **Ticket** | What was asked, status, links, replay command | `LEDGER-NNNN-<slug>/README.md` |
| **Runbook(s)** | Human-readable how-to, one per atomic step | `LEDGER-NNNN-<slug>/runbooks/*.md` |
| **Playbook(s)** | Machine-replayable artifact (Makefile / shell / Ansible / Action / plist / compose) | `LEDGER-NNNN-<slug>/playbooks/*` |

The driving principle: **treat AI invocation as the most expensive resource and force every cycle to compound.** Each AI session that lands a ledger entry removes the need for the next AI session on the same task — the playbook is the receipt.

For the rule that makes adding to the ledger the default closing ritual, see [`.claude/rules/ledger-discipline.md`](../.claude/rules/ledger-discipline.md).

---

## Index

Counter is the source of truth for the next `LEDGER-NNNN`. Bump it when you open a new entry.

**Next number:** `LEDGER-0017`

| ID | Title | Status | Opened | Closed | Replay |
|---|---|---|---|---|---|
| [`LEDGER-0001`](LEDGER-0001-imac-mcp-setup/) | iMac MCP development stack | `shipped` | 2026-05-19 | 2026-05-19 | `make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks install` |
| [`LEDGER-0002`](LEDGER-0002-workflow-debugger-agent/) | workflow-debugger agent (YAML / Bash / JS / Python / Excel) | `shipped` | 2026-05-20 | 2026-05-20 | already loaded at `.claude/agents/workflow-debugger.md`; promote to user scope via `bash ledger/LEDGER-0002-workflow-debugger-agent/playbooks/install-user-scope.sh` |
| [`LEDGER-0003`](LEDGER-0003-vscode-remote-vps/) | VS Code Remote-SSH to vps-godaddy (port 2222, abrownsanta) | `shipped` | 2026-05-20 | 2026-05-20 | `bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh install && code --remote ssh-remote+vps-godaddy /home/abrownsanta` |
| [`LEDGER-0004`](LEDGER-0004-contracts-and-prudence-rollout/) | contracts-and-prudence philosophy rollout (47 marvelousempire repos) | `shipped` | 2026-05-20 | 2026-05-20 | `bash ledger/LEDGER-0004-contracts-and-prudence-rollout/playbooks/rollout.sh dry-run && bash …/rollout.sh apply` |
| [`LEDGER-0005`](LEDGER-0005-gitlab-as-source-of-truth/) | GitLab CE sovereign source-of-truth (Phase 1 shipped: https://git.yousirjuan.ai) | `phase-1-shipped` | 2026-05-20 | _pending_ | Phase 1: live; Phase 2 + 3 TODO |
| [`LEDGER-0006`](LEDGER-0006-gitlab-warm-standby/) | GitLab CE warm-standby on the iMac (VPS-primary, iMac-secondary) | `in-progress` | 2026-05-20 | _pending_ | `bash ledger/LEDGER-0006-gitlab-warm-standby/playbooks/install-standby.sh install` (after operator does OrbStack + Tailscale + Energy Saver prereqs) |
| [`LEDGER-0007`](LEDGER-0007-imac-emergency-failsafe/) | iMac emergency failsafe for VPS (3-min watchdog + auto DNS swap) | `phase-1-shipped` | 2026-05-20 | _pending_ | `bash ledger/LEDGER-0007-imac-emergency-failsafe/playbooks/install-watchdog.sh install` (dry-run by default; see runbook 03 to go live) |
| [`LEDGER-0008`](LEDGER-0008-watchdog-control-surface/) | Watchdog control surface — state server (iMac) + Nephew card + DustPan settings | `in-progress` | 2026-05-20 | _pending_ | `bash ledger/LEDGER-0008-watchdog-control-surface/playbooks/install-state-server.sh install` (Phase 1; Nephew + DustPan PRs separate) |
| [`LEDGER-0009`](LEDGER-0009-watchdog-tamer/) | Watchdog Tamer — Ollama agent that suggests config changes | `planning` | 2026-05-20 | _pending_ | (ticket only; implementation TBD per ADR-0001 — Ollama on iMac, not VPS) |
| [`LEDGER-0010`](LEDGER-0010-sandbox-cli-generator/) | Sandbox CLI generator — `make sandbox <tool>` for containerizing the unruly | `in-progress` | 2026-05-20 | _pending_ | `make -C ledger/LEDGER-0010-sandbox-cli-generator/playbooks build run tool=grok-cli` (Grok CLI Beta is the first concrete sandbox) |
| [`LEDGER-0011`](LEDGER-0011-vps-memory-hardening/) | VPS memory hardening — GitLab caps + sshd OOM protect + double swap | `partially-applied` | 2026-05-20 | _pending_ | `sudo bash ledger/LEDGER-0011-vps-memory-hardening/playbooks/apply-all.sh` (steps 2+3 applied today; step 1 staged for next GitLab restart) |
| [`LEDGER-0012`](LEDGER-0012-vps-observability-control/) | VPS observability + control agent — /system /processes /docker /sites /entities /kill | `shipped` | 2026-05-20 | 2026-05-20 | `sudo bash ledger/LEDGER-0012-vps-observability-control/playbooks/install-vps-agent.sh install` (on VPS); Nephew + DustPan UIs consume |
| [`LEDGER-0013`](LEDGER-0013-clinic-fix-and-vhost-audit/) | Clinic vhost fix + nginx upstream audit + wire-marvelous-app generator | `in-progress` | 2026-05-21 | _pending_ | `sudo bash ledger/LEDGER-0013-clinic-fix-and-vhost-audit/playbooks/audit-vhost-upstreams.sh` (on VPS) + `wire-marvelous-app.sh` for new apps |
| [`LEDGER-0014`](LEDGER-0014-operator-intent-protocol/) | Operator-intent protocol — cross-agent ops notes (intent files + MOTD hook + systemd mask) | `in-progress` | 2026-05-21 | _pending_ | `sudo bash ledger/LEDGER-0014-operator-intent-protocol/playbooks/intent.sh add <topic> "<desc>" "<why>" [--mask-service <unit>]` |
| [`LEDGER-0015`](LEDGER-0015-server-stability-suite/) | Server Stability Suite — proactive killer + /history endpoint + macOS notifications | `in-progress` | 2026-05-21 | _pending_ | VPS: `sudo bash ledger/LEDGER-0015-server-stability-suite/playbooks/install-server-tamer.sh install` · iMac: `bash …/install-alert-watch.sh install` |
| [`LEDGER-0016`](LEDGER-0016-uptime-kuma-monitoring/) | Uptime Kuma — external uptime monitoring + multi-channel alerts (Telegram / email / Pushover) | `in-progress` | 2026-05-21 | _pending_ | `sudo bash ledger/LEDGER-0016-uptime-kuma-monitoring/playbooks/install.sh install` (on VPS) + GoDaddy A record + certbot |

> LEDGER-0001 was originally captured at `docs/sessions/2026-05-19-mcp-setup/` (PR #4) as the embryo of this pattern. It was migrated into the ledger and reshaped (`artifacts/Makefile` → `playbooks/Makefile`, new ticket README, new `install.sh` shell sibling, ticket frontmatter) in the migration PR that landed alongside this row.

---

## How to add an entry

1. **Pick the next number.** Read the "Next number" line above, claim it, and bump the line in your PR.
2. **Copy the template.**
   ```
   cp -R ledger/_template ledger/LEDGER-NNNN-<kebab-slug>
   ```
3. **Fill out `LEDGER-NNNN-<slug>/README.md`** (the ticket) per the schema below.
4. **Write the runbook(s)** under `runbooks/`. Split into separate files if the task has independent atomic steps — the goal is microscopic, reusable units.
5. **Write the playbook(s)** under `playbooks/`. See the format-choice guide below. **Strictly AI-free** — if the task can't be expressed without an AI step, ship the runbook only and note it in the ticket.
6. **Add a row to the index above** with status `in-progress`.
7. **Close** by setting `status: shipped`, filling `closed:`, and updating the index row.

---

## Ticket schema (`LEDGER-NNNN-<slug>/README.md`)

```markdown
---
ledgerId: LEDGER-NNNN
title: Short imperative phrase
status: in-progress | shipped | superseded
opened: YYYY-MM-DD
closed: YYYY-MM-DD                     # null if in-progress
related-pains: [PAIN-NNNN]             # optional; cross-link to pain-journal/
related-tickets: []                    # other LEDGER ids this builds on
triggers: []                           # e.g. [launchd:user-login, github-actions:push]
---

# LEDGER-NNNN — Title

## Ask
What the operator asked for, in their words if possible.

## Outcome
One-paragraph summary of what shipped.

## Runbooks
- [01-foo.md](runbooks/01-foo.md) — one-line summary

## Playbooks
- [Makefile](playbooks/Makefile) — `make install` (idempotent)
- [install.sh](playbooks/install.sh) — idempotent shell, logs to `~/yousirjuan-ledger.log`

## Replay (zero-AI)
The single command to re-execute this task without invoking an agent.

## Verification
How to know it succeeded.

## Undo
How to revert.
```

---

## Format-choice guide

Pick the artifact format that best fits the task. Multiple are allowed per entry (e.g. a Makefile dispatcher that calls into shell + invokes a launchd plist).

| Task type | Reach for | Notes |
|---|---|---|
| Dev workflow with multiple related ops | **Makefile** | `@echo "→ ..."`, vars at top, `help` default target |
| One-shot install / setup | **shell script** (`install.sh`) | Sources `step/ok/warn/die/have` helpers, logs to `~/yousirjuan-ledger.log`, idempotent guards |
| Multi-host config (iMac + VPS + Macbook) | **Ansible playbook** | Optional dependency — install `ansible` only when reaching for it |
| Scheduled / push / PR triggered | **GitHub Actions YAML** | Under `.github/workflows/` with a symlink or copy in the entry's `playbooks/` |
| Persistent macOS background service | **launchd plist** | Under `~/Library/LaunchAgents/` for per-user, `/Library/LaunchDaemons/` for system |
| Container service stack | **docker-compose** snippet | Lives in entry's `playbooks/`, can be referenced from the root compose file |
| Anything that needs AI judgment | **Runbook only — no playbook** | Note it in the ticket: "no playbook because <reason>" |

---

## Conventions reused across playbooks

Every shell playbook reuses the existing yousirjuan helper-function set so new automation looks like old automation. Examples lifted from `tools/health.sh` and `installers/intel-mac/install.sh`:

```bash
# colors + helpers — copy-paste into any new shell playbook
LOG_FILE="${HOME}/yousirjuan-ledger.log"
exec > >(tee -a "$LOG_FILE") 2>&1

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; BOLD='\033[1m'; NC='\033[0m'

step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }
```

Idempotency patterns (any new playbook should use these):

```bash
# tool installed?
have docker || die "docker not installed"

# file already in place?
[[ -f "$config_path" ]] && { note "$config_path exists, skipping"; return 0; }

# symlink already correct?
[[ -L "$link" ]] && [[ "$(readlink "$link")" == "$target" ]] && { ok "symlink already correct"; return 0; }
```

For Makefile-style playbooks, see [`ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile`](LEDGER-0001-imac-mcp-setup/) (once migrated) — it's the canonical example.

---

## Triggers — how playbooks fire without you typing

A playbook is just an artifact. Triggers are how it runs on schedule, on event, or on login. Patterns:

| Trigger | Wired via | Example |
|---|---|---|
| Manual CLI | none — just run it | `make -C ledger/LEDGER-0001-.../playbooks install` |
| User login | `launchd` plist in `~/Library/LaunchAgents/` | Ollama auto-start (LEDGER-0001) |
| Boot / system | `launchd` plist in `/Library/LaunchDaemons/` (sudo) | system services |
| Cron / scheduled | `launchd StartCalendarInterval` or `cron` | nightly backup |
| Push / PR / dispatch | `.github/workflows/*.yml` | CI checks |
| File change | `launchd WatchPaths` or `fswatch` + shell | watch-and-rebuild |

The entry's ticket declares its triggers in frontmatter (`triggers: [launchd:user-login]`). Multiple triggers per entry are fine.

---

## Ledger ≠ Pain-Journal, Ledger ≠ Skills

| Lives at | What it captures |
|---|---|
| `pain-journal/PAIN-NNNN.md` | A **problem** to solve — user frustration that may become a feature |
| `ledger/LEDGER-NNNN-<slug>/` | A **shipped solution** — task captured as replayable artifact |
| `vendor/ai-skills-library/skills/.../SKILL.md` | A **reusable procedure** — template/instruction for an agent |

Pain entries describe what hurts. Ledger entries describe what was done about it. Skills describe how an agent should approach a class of work in general. Cross-link with `related-pains:` in the ticket.

---

## Open follow-ups (not yet committed)

- **CI hardening** — after ~5 real entries, add a check that fails PRs touching `runbooks/**` or `playbooks/**` outside a `LEDGER-NNNN/` folder.
- **PAIN ↔ LEDGER cross-link script** — scan new entries' `related-pains:` frontmatter and add back-pointers in the corresponding PAIN files.
- **`yousirjuan ledger` CLI** — thin convenience commands (`ledger new <slug>`, `ledger replay <id>`, `ledger list`) once the pattern stabilizes.
