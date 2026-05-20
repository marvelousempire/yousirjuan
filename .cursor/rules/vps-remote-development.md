---
description: How to connect to the yousirjuan VPS (vps-godaddy) for remote development. Use when the user mentions "the VPS," "the server," "remote development," SSH issues to vps-godaddy, or asks how to open a remote editor on the production box. Single source of truth is the LEDGER-0003 ledger entry; this file is the Cursor-discoverable pointer.
globs: ["**/*.sh", "**/*.yml", "**/*.yaml", "ledger/**/*", "docs/**/*", "vps/**/*", ".ssh/**/*"]
alwaysApply: false
---

# VPS remote development — `vps-godaddy`

**Canonical:** [`ledger/LEDGER-0003-vscode-remote-vps/`](../../ledger/LEDGER-0003-vscode-remote-vps/) — read the ticket README there for the full picture; don't duplicate what's in the ledger.

## At-a-glance

The yousirjuan VPS lives at `72.167.151.251` (GoDaddy, Ubuntu 24.04). SSH is on **port 2222**, not the default 22. User is `abrownsanta`. The local SSH config alias is `vps-godaddy`.

Connect from VS Code (or Cursor — same Remote-SSH extension):

```bash
code --remote ssh-remote+vps-godaddy /home/abrownsanta
```

Or from any SSH-capable terminal:

```bash
ssh vps-godaddy
```

The SSH alias should already be in `~/.ssh/config`. If it's not, run:

```bash
bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh install
```

…which is idempotent and prompts before mutating `~/.ssh/config`.

## When this rule is relevant

Trigger this rule's content into the model's context when the user is:

- Trying to SSH into the VPS and getting "refused," "permission denied," "timeout," or similar.
- Opening a remote VS Code / Cursor window on the VPS.
- Setting up a brand-new Mac that needs VPS access.
- Editing files under `vps/` (the deployment scripts).
- Talking about Open WebUI, Ollama, nginx, fail2ban, or systemd services — those run on this VPS.

Don't trigger it for unrelated work (frontend changes, repo docs, ledger CRUD).

## Where to look first when something's wrong

1. **Status check:** `bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh status` — six ✓/⚠ lines that tell you which layer is broken.
2. **Triage script:** `bash ledger/LEDGER-0003-vscode-remote-vps/playbooks/install.sh test` — runs the 90-second read-only triage and prints pattern-matchable output.
3. **Decision tree:** [`ledger/LEDGER-0003-vscode-remote-vps/runbooks/04-troubleshoot-refused-connections.md`](../../ledger/LEDGER-0003-vscode-remote-vps/runbooks/04-troubleshoot-refused-connections.md) — six patterns (A through F) with the exact "what fixed it" for each. Match against your symptoms.

## Don't get bitten by

- **Port 22 is closed on this VPS.** Default `ssh user@host` will say "Connection refused." Use the `vps-godaddy` alias or explicit `-p 2222`.
- **"Permission denied (publickey)" with `Server accepts key:` earlier in `ssh -v` output is NOT an authorization failure.** It's BatchMode suppressing the macOS Keychain passphrase prompt. Drop `-o BatchMode=yes`, enter the passphrase once interactively, then non-interactive calls work.
- **Don't mutate `~/.ssh/config` without explicit per-edit consent.** Feedback memory `feedback_dont_mutate_user_config_silently.md` captures the rule. Use the playbook's interactive `install` action; it prompts before writing.
- **Don't iterate auth attempts.** Fail2ban bans the source IP after 5 failed SSH attempts. Get the alias right the first time using the canonical snippet at [`ledger/LEDGER-0003-vscode-remote-vps/artifacts/ssh-config-snippet.txt`](../../ledger/LEDGER-0003-vscode-remote-vps/artifacts/ssh-config-snippet.txt).

## Related repo conventions

- Ledger discipline: [`.claude/rules/ledger-discipline.md`](../../.claude/rules/ledger-discipline.md) — every non-trivial task goes in `/ledger/` with ticket + runbook + playbook.
- CLI snippet formatting: [`.claude/rules/cli-snippet-formatting.md`](../../.claude/rules/cli-snippet-formatting.md) — emit shell commands as a single copy-pasteable block.
- Contract enforcement: [`REPOS-CONTRACT.md`](../../REPOS-CONTRACT.md) — yousirjuan is infrastructure-only; the VPS itself is in scope.
