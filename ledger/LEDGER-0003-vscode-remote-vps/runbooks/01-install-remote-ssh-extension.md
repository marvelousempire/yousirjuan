# Runbook 01 — Install VS Code Remote-SSH extension

**Time:** ~30 seconds (depends on download speed)
**Reversible:** yes (`code --uninstall-extension ms-vscode-remote.remote-ssh`)
**Prereqs:** `code` CLI on PATH (see [LEDGER-0001 runbook 01](../../LEDGER-0001-imac-mcp-setup/runbooks/01-install-code-cli.md) if missing)

## Why

VS Code's **Remote-SSH** extension is what lets a local VS Code window open a workspace that lives on a remote machine. All file edits, terminals, and most extensions run on the remote; only the UI runs locally. It's how you develop on a VPS without losing your editor.

The extension pack `ms-vscode-remote.remote-ssh` automatically pulls two dependencies — `ms-vscode-remote.remote-ssh-edit` (remote file editing) and `ms-vscode.remote-explorer` (the side panel for managing remote connections). One install gets you all three.

## Steps

```bash
code --install-extension ms-vscode-remote.remote-ssh
```

Expected output (or similar; versions vary):

```
Extension 'ms-vscode-remote.remote-ssh-edit' v0.87.0 was successfully installed.
Extension 'ms-vscode.remote-explorer' v0.5.0 was successfully installed.
```

The third extension (the main `ms-vscode-remote.remote-ssh` itself) is installed silently when its deps are pulled. Verify with:

```bash
code --list-extensions | grep -iE "remote-ssh|remote.explorer"
```

…which should show three lines.

## Success criteria

- `code --list-extensions | grep remote-ssh` returns at least `ms-vscode-remote.remote-ssh` (and probably the `-edit` variant too).
- Open VS Code → bottom-left status bar should show a "remote" indicator (a small `><` icon) — click it to see Remote-SSH commands.

## Undo

```bash
code --uninstall-extension ms-vscode-remote.remote-ssh && \
code --uninstall-extension ms-vscode-remote.remote-ssh-edit && \
code --uninstall-extension ms-vscode.remote-explorer
```

## Notes and gotchas

- **`code` CLI required.** If `which code` returns nothing, see [LEDGER-0001 runbook 01](../../LEDGER-0001-imac-mcp-setup/runbooks/01-install-code-cli.md) — install the shim first.
- **The extension is per-user, not per-workspace.** Installing it once is enough; it's available in any VS Code window after.
- **Already installed?** `code --install-extension` is idempotent — it prints "is already installed" and exits 0. Safe to re-run from automation.

## Related

- Next: [02-configure-ssh-alias.md](02-configure-ssh-alias.md) — wire up `~/.ssh/config` so VS Code knows how to reach the VPS.
- Playbook: [`playbooks/install.sh`](../playbooks/install.sh) `install` action runs this step automatically.
