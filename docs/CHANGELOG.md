# Changelog

All notable changes to **yousirjuan** ship here. Format follows the convention in [`.claude/rules/changelog-and-versioning.md`](../.claude/rules/changelog-and-versioning.md):

```
## [0.x.y] — YYYY-MM-DD HH:MM:SS Eastern · *short tagline*
```

Eastern time stamped to the second using `TZ=America/New_York date '+%Y-%m-%d %H:%M:%S'`. Newest entries first.

---

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
