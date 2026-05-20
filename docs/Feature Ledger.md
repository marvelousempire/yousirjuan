# Feature Ledger

Per-feature status grid for **yousirjuan**. Status symbols:

- ✅ **Shipped** — live in production / on main, verified working
- ✔️ **In progress** — landed partial, behind a flag, or has a known follow-up
- 🔜 **Planned** — has an owner / ledger entry / RFC; not yet started
- ❌ **Dropped / out of scope** — explicitly decided against

Update this file in the same PR as any status change. Reference the [LEDGER entry](../ledger/) and [PRs](../.github/PULL_REQUEST_TEMPLATE.md) for the trail of who/when/why.

---

## Platform infrastructure

| Feature | Status | Where it lives | Notes |
|---|---|---|---|
| **Self-codifying ledger system** | ✅ | [`ledger/`](../ledger/) + [`.claude/rules/ledger-discipline.md`](../.claude/rules/ledger-discipline.md) | Every non-trivial task → ticket + runbook + executable playbook. Index at [`ledger/README.md`](../ledger/README.md). Shipped 0.2.0. |
| **iMac MCP development stack** | ✅ | [`ledger/LEDGER-0001-imac-mcp-setup/`](../ledger/LEDGER-0001-imac-mcp-setup/) | VS Code + Cline + Ollama-as-LaunchAgent, all reproducible via `make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks install`. Shipped 0.2.0. |
| **`workflow-debugger` agent** | ✅ | [`.claude/agents/workflow-debugger.md`](../.claude/agents/workflow-debugger.md), [`ledger/LEDGER-0002-workflow-debugger-agent/`](../ledger/LEDGER-0002-workflow-debugger-agent/) | Claude Code project-scoped agent for YAML/Bash/JS/Python/Excel pipeline failures. Promotable to user scope via install playbook. Shipped 0.2.0. |
| **Auto-sync hook for workflow-debugger** | ✅ | [`.claude/settings.json`](../.claude/settings.json) PostToolUse | Re-syncs agent project→user on Edit. Controllable via `/hooks` slash command. Shipped 0.2.0. |
| **Contract-enforcement CI** | ✅ | [`.github/workflows/contract-enforcement-no-persona.yml`](../.github/workflows/contract-enforcement-no-persona.yml) | Allowlist-based. Loosened in 0.2.0 to stop blocking on its own meta-doc. |
| **Intel-Mac one-liner installer** | ✅ | [`installers/intel-mac/install.sh`](../installers/intel-mac/install.sh) + [`.github/workflows/release-intel-mac.yml`](../.github/workflows/release-intel-mac.yml) | YAML parse bug fixed in 0.2.0 — workflow now correctly fires only on `v*.*.*` tag pushes. |
| **Docker runtime stack** | ✅ | [`docker-compose.yml`](../docker-compose.yml), [`docker-compose.runtime.yml`](../docker-compose.runtime.yml) | Ollama / Open WebUI / Postgres / Redis / Qdrant / Kokoro / nginx. |
| **VPS deployment scripts** | ✅ | [`vps/`](../vps/) | `apply-vps-config.sh`, nginx template, iptables lockdown, fail2ban, ollama systemd override. |
| **Helper-function set** (`step / ok / warn / die / have`) | ✅ | every shell script in `installers/`, `tools/`, `vps/` | Canonical across the repo. Documented in [`ledger/README.md`](../ledger/README.md). |

## Agent layer

| Feature | Status | Where it lives | Notes |
|---|---|---|---|
| **Claude Code project-scoped agents** convention | ✅ | [`.claude/agents/`](../.claude/agents/) | Project-scoped agents discovered automatically; user-scope promotion available per agent. |
| **`.claude/rules/` discipline** | ✅ | [`.claude/rules/`](../.claude/rules/) | dev-discipline, changelog-and-versioning, go-live-path, parallel-surfaces-from-day-one, ledger-discipline, cli-snippet-formatting. |
| **`Bishop` agent factory consolidation** (merge `bishop-factory` → `bishop`) | 🔜 | external repos (`marvelousempire/bishop`, `marvelousempire/bishop-factory`) | Two repos are byte-identical duplicates. Plan documented at [`~/.claude/plans/what-is-the-best-curious-willow.md`](~/.claude/plans/what-is-the-best-curious-willow.md) §"Part 2". |
| **`Nephew` orchestration agent** | (not in this repo) | external `marvelousempire/nephew` | yousirjuan is infrastructure-only per REPOS-CONTRACT.md. Nephew is the user-facing orchestrator. |

## Operator-facing apps

| Feature | Status | Where it lives | Notes |
|---|---|---|---|
| `yousirjuan-web` | ✔️ | [`apps/yousirjuan-web/`](../apps/yousirjuan-web/) | Next.js 15 + Tailwind 4. Build / dev / e2e per [`apps/README.md`](../apps/README.md). v0.2.0. |
| `yousirjuan-ios` | ✔️ | [`apps/yousirjuan-ios/`](../apps/yousirjuan-ios/) | SwiftUI + RealityKit 4 kiosk interface. `xcodegen generate` to refresh. **Version cycle is independent of the platform** — currently at `CFBundleShortVersionString = 1.0` / `CFBundleVersion = 1` in [`Info.plist`](../apps/yousirjuan-ios/Sources/Info.plist). Bumps follow App Store review cycles, not platform `0.x` cycles. |
| `admin` dashboard | ✔️ | [`apps/admin/`](../apps/admin/) | v0.2.0. |
| `homekit-bridge` | ✔️ | [`services/homekit-bridge/`](../services/homekit-bridge/) | HomeKit local control surface. v0.2.0. |

## Pain → feature pipeline

Tracked in [`pain-journal/`](../pain-journal/). PAIN entries pointing at a yousirjuan-shaped feature:

| Pain | Status | Feature |
|---|---|---|
| `PAIN-0006` Ollama.app incompatible on Ventura | ✅ resolved by LEDGER-0001 | `make ollama-agent` LaunchAgent install path |
| `PAIN-0007` `code` CLI not on PATH | ✅ resolved by LEDGER-0001 | `make code-cli` symlink |
| `PAIN-0008` Copilot Chat paywall | ✅ resolved by LEDGER-0001 | Cline + OpenRouter free tier path |
| `PAIN-0009` MCP config fragmented across clients | ✔️ partially resolved | Both client configs written in lockstep by `make install`. Long-term fix: yousirjuan MCP registry (🔜) |
| `PAIN-0010` Intel CPU no GPU | ✔️ partially resolved | Documented recommendation. Long-term fix: inference router (🔜) |

## Open follow-ups (🔜 with owners or RFCs)

| Item | Where |
|---|---|
| CI hardening for the ledger pattern (fail PRs touching `runbooks/**` / `playbooks/**` outside a `LEDGER-NNNN/`) | Wait until ~5 real entries; see [`.claude/rules/ledger-discipline.md`](../.claude/rules/ledger-discipline.md). |
| Bishop / bishop-factory consolidation | Plan at [`~/.claude/plans/what-is-the-best-curious-willow.md`](~/.claude/plans/what-is-the-best-curious-willow.md). |
| PAIN ↔ LEDGER cross-link automation | Documented in [`ledger/README.md`](../ledger/README.md) open follow-ups. |
| `yousirjuan ledger` CLI (counter bump + template copy + index update) | Documented in [`ledger/README.md`](../ledger/README.md) open follow-ups. |
| `runs-on: macos-13` in release-intel-mac.yml — may be deprecated by Apple by 2026-05-20 | Out of scope for [PR #10](https://github.com/marvelousempire/yousirjuan/pull/10); fix when next `v*.*.*` tag push surfaces a scheduler failure. |
| `PUBLIC_REPO_TOKEN` secret configuration | Required for the first real release. Configure in repo settings before pushing `v*.*.*`. |
