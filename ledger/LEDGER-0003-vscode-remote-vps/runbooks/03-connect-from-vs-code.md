# Runbook 03 — Open a remote VS Code window on `vps-godaddy`

**Time:** ~30s on first connection (VS Code Server install on remote); ~3s on subsequent connections
**Reversible:** yes (close the remote window, or `code --uninstall-extension` to fully remove)
**Prereqs:** runbooks [01](01-install-remote-ssh-extension.md) and [02](02-configure-ssh-alias.md) complete; `ssh vps-godaddy 'echo ok'` succeeds non-interactively

## Why

Once the extension and the SSH alias are in place, opening a remote workspace is a single command (CLI) or three clicks (UI). The first connection has overhead: VS Code Server (~200 MB) is downloaded and installed on the VPS. After that, every connect is fast.

## Steps

### Option A — CLI one-liner (fastest, scriptable)

```bash
code --remote ssh-remote+vps-godaddy /home/abrownsanta
```

A new VS Code window opens, the bottom-left status bar shows `SSH: vps-godaddy`, and the file explorer is rooted at `/home/abrownsanta` on the VPS. First-connection prompts that appear:

1. **Host fingerprint** — VS Code shows a banner: "The authenticity of host '72.167.151.251 (...)' can't be established. ED25519 key fingerprint is SHA256:...". Click **Continue**. The fingerprint is cached into `~/.ssh/known_hosts`.
2. **Passphrase prompt** for `id_ed25519` — macOS Keychain dialog appears once. Tick "Always allow" so it's silent on subsequent sessions.
3. **VS Code Server install on the remote** — progress shown in the bottom status bar. ~30s on a fast connection.

### Option B — UI flow (good for the first time, discoverable)

1. Open VS Code.
2. **⇧⌘P** to open the command palette.
3. Type **Remote-SSH: Connect to Host…** and select it.
4. Pick **`vps-godaddy`** from the list (the alias appears because of the SSH config from runbook 02).
5. Same first-connection prompts as Option A.

### Option C — Click the status bar

If a remote workspace is already open, the bottom-left **`SSH: vps-godaddy`** badge is a click target:

- Click → menu with "Reopen Folder in SSH…", "Close Remote Connection", "Show Log", etc.

Useful when you're already remote and want to switch directories or disconnect.

## Smoke test once connected

Open a terminal in the remote VS Code (`⌃` `` ` ``) and run:

```bash
hostname && \
uname -a && \
docker ps --format 'table {{.Names}}\t{{.Status}}' && \
sudo systemctl is-active ollama tailscaled nginx fail2ban
```

Expected:
- `hostname`: the VPS's hostname.
- `uname`: `Linux ... Ubuntu`.
- `docker ps`: running containers (likely `open-webui`, etc.).
- `systemctl`: each service prints `active`.

This proves you're actually on the VPS, not on the local Mac.

## Success criteria

- VS Code window's bottom-left shows `SSH: vps-godaddy`.
- File explorer shows VPS paths (e.g., `/home/abrownsanta`, NOT `/Users/averygoodman`).
- A terminal opened in that VS Code window's terminal panel runs commands on the VPS (`hostname` returns the VPS name).
- Subsequent reconnects don't re-trigger the VS Code Server install (you see "Connecting…" for ~3s, then it's open).

## Undo

```bash
# Close the remote VS Code window (Cmd+W or Cmd+Shift+P → Remote-SSH: Close Remote Connection).
# To fully reset the remote-side install:
ssh vps-godaddy 'rm -rf ~/.vscode-server'
# Next connection will re-download VS Code Server.
```

## Notes and gotchas

- **VS Code Server lives at `~/.vscode-server` on the remote.** It's user-scoped; doesn't affect other users on the VPS. Takes ~200 MB.
- **Reconnect after VPS reboot is silent.** SSH keepalive (`ServerAliveInterval 60` in the alias) keeps the connection warm. If the VPS reboots, VS Code reconnects automatically when it returns.
- **Don't open very large workspaces** (>50k files) over a slow connection — VS Code's file watcher walks the whole tree on connect, which can pause the UI. Open a specific subdirectory instead of `/home/abrownsanta` if the home dir is huge.
- **Extensions are split.** Extensions that operate on text (linters, formatters) install on the remote side automatically when you open files. UI extensions (themes, vim, copilot) stay on the local side. Most things "just work."
- **Settings: `remote.SSH.useLocalServer`** — set to `true` (default). Tells VS Code to use the system `ssh` binary (which reads `~/.ssh/config`). If this is `false`, VS Code uses a built-in SSH that misses Keychain integration — surface a refused connection that looks like an auth issue but is really a "wrong SSH client" issue. Confirm at **Cmd+,** → search "remote.SSH.useLocalServer".
- **Settings: `remote.SSH.configFile`** — leave empty (default). Points VS Code at a custom SSH config file; if set to the wrong path, the `vps-godaddy` alias won't be discoverable.

## Related

- Previous: [02-configure-ssh-alias.md](02-configure-ssh-alias.md).
- Troubleshooting: [04-troubleshoot-refused-connections.md](04-troubleshoot-refused-connections.md).
- For the operator-facing "what to expect" list: see the ticket README's "Replay" section.
