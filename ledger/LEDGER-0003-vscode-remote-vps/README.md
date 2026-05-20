---
ledgerId: LEDGER-0003
title: VS Code Remote-SSH connection to the VPS (vps-godaddy)
status: shipped
opened: 2026-05-20
closed: 2026-05-20
related-pains: []
related-tickets: []
triggers:
  - manual-cli: `code --remote ssh-remote+vps-godaddy /home/abrownsanta`
  - manual-ui: `⇧⌘P → Remote-SSH: Connect to Host… → vps-godaddy`
---

# LEDGER-0003 — VS Code Remote-SSH connection to the VPS

## Ask

> "connect my VS Code to my server VPS"

…and then, after one round of debugging when the operator reported "it keeps getting refused":

> "Teach what you did to get the server up and running to yousirjuan's repo memory and to its claude memory and its cursor memory and its all access all agents knowledge too"

## Outcome

The operator's iMac can now open a remote VS Code window on `vps-godaddy` (the GoDaddy Ubuntu 24.04 box at `72.167.151.251`, user `abrownsanta`, SSH on **port 2222**). Three independent name resolutions all route correctly: the friendly alias, the verbose `*.host.secureserver.net` hostname, and the raw IP. Authentication uses the operator's `~/.ssh/id_ed25519` key, which is **already authorized server-side** — the passphrase comes from macOS Keychain on first interactive use of the session, then SSH agent caches it for the rest of the login.

What this entry teaches (and where each piece is durable):

- The **diagnostic process** (port 22 was refused → checked port 2222 with `nc -z` → opened → tried SSH on 2222 → server accepts key → "permission denied" was actually `BatchMode=yes` suppressing the Keychain prompt) — captured in [runbook 04](runbooks/04-troubleshoot-refused-connections.md).
- The **install steps** (VS Code Remote-SSH extension, SSH config alias) — captured in [runbook 01](runbooks/01-install-remote-ssh-extension.md) and [runbook 02](runbooks/02-configure-ssh-alias.md).
- The **connect steps** (CLI + UI paths) — captured in [runbook 03](runbooks/03-connect-from-vs-code.md).
- The **automation** (one-shot idempotent script that lays the whole thing down on a fresh Mac) — captured in [`playbooks/install.sh`](playbooks/install.sh).

This entry is reachable from multiple agent surfaces (Claude Code's `.claude/`, Cursor's `.cursor/rules/`, the tool-neutral `AGENTS.md` at repo root, and the ledger index) so any agent — current or future — landing in this repo with the task "set up VS Code on a new Mac to reach the VPS" finds it on first scan.

## Runbooks

- [01-install-remote-ssh-extension.md](runbooks/01-install-remote-ssh-extension.md) — install `ms-vscode-remote.remote-ssh` (and dependent extensions) on a fresh VS Code
- [02-configure-ssh-alias.md](runbooks/02-configure-ssh-alias.md) — add a `Host vps-godaddy` block to `~/.ssh/config`. Includes the explicit caveat about port 2222 (not 22) and the macOS Keychain integration
- [03-connect-from-vs-code.md](runbooks/03-connect-from-vs-code.md) — the actual "open a remote VS Code window" steps (CLI one-liner + UI flow), what to expect on first connection (VS Code Server install on the VPS, fingerprint prompt, Keychain unlock)
- [04-troubleshoot-refused-connections.md](runbooks/04-troubleshoot-refused-connections.md) — the diagnostic playbook: how to tell whether "refused" is a network layer / port / auth / Keychain / VS Code config issue, and the cheap `nc -z` + `ssh -G` + `ssh -v` commands that disambiguate each in under a minute

## Playbooks

- [install.sh](playbooks/install.sh) — single-action idempotent script. Detects what's already installed, prompts before mutating `~/.ssh/config`, no-ops if everything is already in place. Logs to `~/yousirjuan-ledger.log`. Usage:
  ```bash
  bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh install
  bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh status
  bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh test
  ```

## Artifacts

- [ssh-config-snippet.txt](artifacts/ssh-config-snippet.txt) — the canonical `Host vps-godaddy` stanza (single source of truth; both the runbook and the playbook reference this file rather than duplicating)

## Replay (zero-AI)

On a fresh Mac that has VS Code installed and an SSH key authorized server-side:

```bash
git clone https://github.com/marvelousempire/yousirjuan.git ~/Developer/yousirjuan && \
cd ~/Developer/yousirjuan && \
bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh install && \
code --remote ssh-remote+vps-godaddy /home/abrownsanta
```

If the SSH key isn't authorized server-side yet, the playbook says so explicitly and points at the public key to copy.

## Verification

After running the install playbook, the `status` action reports every piece:

```bash
bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh status
```

…should print ✓ for: Remote-SSH extension installed, `Host vps-godaddy` alias resolves to port 2222, ssh-agent has the key loaded, port 2222 reachable, and a non-interactive SSH test succeeds.

## Undo

```bash
bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh uninstall
```

Removes the `Host vps-godaddy` alias from `~/.ssh/config` (after confirming with the operator), uninstalls the Remote-SSH extension, drops the VS Code workspace's `.vscode/settings.json` server fingerprint if present. Leaves the verbose-hostname and IP-only SSH entries alone since those may be used by other tools.

## Why this entry is multi-surfaced

The operator's explicit request was to make this knowledge reachable from yousirjuan's repo memory **AND** its Claude memory **AND** its Cursor memory **AND** any other agent that ever lands in this repo. Single-surface knowledge gets lost. The pattern used:

| Surface | Path | Role |
|---|---|---|
| Canonical (this entry) | [`ledger/LEDGER-0003-vscode-remote-vps/`](.) | Single source of truth — runbooks, playbook, artifacts, ticket |
| Repo memory (Claude Code) | [`.claude/agents/`](../../.claude/agents/) + [`.claude/rules/`](../../.claude/rules/) + [`CLAUDE.md`](../../CLAUDE.md) | Existing Claude-Code-readable surface; CLAUDE.md gains a pointer to this ledger entry |
| Repo memory (Cursor) | [`.cursor/rules/vps-remote-development.md`](../../.cursor/rules/vps-remote-development.md) | Cursor-readable rule that mirrors the operator-facing summary + points at this ledger entry for the deep dive |
| Tool-neutral entrypoint | [`AGENTS.md`](../../AGENTS.md) | Repo-root file any new agent reads at session start. Lists `/ledger/` as the canonical home and names LEDGER-0003 explicitly as an example of "VPS access" knowledge |

## Notes

- **Operator's home-dir SSH config was edited earlier in the same session** (twice — both the new `Host vps-godaddy` alias and a port-22→2222 fix to the pre-existing verbose-hostname entry). That happened before this ledger entry; the live state of `~/.ssh/config` is what the operator currently has, and the playbook here is what would land the same state on a fresh Mac without mutation surprise.
- **Tailscale is logged out** on the originating iMac at the time of this entry — so the tailnet name `vps-godaddy.tailaa31dd.ts.net` doesn't resolve. The runbook + playbook use the public IP path; switching to Tailscale is a separate ledger entry when Tailscale comes back online.
- **The "permission denied" red herring on port 2222** taught a generally-useful lesson about diagnosing SSH failures: "Server accepts key" + "Permission denied (publickey)" in `ssh -v` output is almost always BatchMode-blocked passphrase signing, not actual authorization failure. Captured in runbook 04. The `workflow-debugger` agent (LEDGER-0002) is a natural future expansion target if SSH/connectivity bugs become a recurring class.
