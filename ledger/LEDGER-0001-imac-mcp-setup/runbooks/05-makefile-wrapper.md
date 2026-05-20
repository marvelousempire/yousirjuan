# Runbook 05 — Single-command Makefile for the whole MCP stack

**Time:** ~30 seconds to lay down the file, then `make install` does everything.
**Reversible:** yes (`make uninstall`)
**Prereqs:** GNU/BSD `make` (ships with macOS as part of Command Line Tools)

## Why

Runbooks 01–04 are the human-readable explanation of each piece. This runbook is the **executable** version — a Makefile that performs the same steps idempotently and surfaces them as named targets:

| Target | Purpose |
|---|---|
| `make install` | Run every step (idempotent — safe to re-run) |
| `make uninstall` | Remove every artifact this Makefile installs |
| `make status` | Show current state of every piece |
| `make start` / `stop` / `restart` | Control the Ollama LaunchAgent |
| `make check-prereqs` | Verify VS Code, npx, ollama are present |
| `make help` (default) | Print this list |

The Makefile lives at `/Users/averygoodman/Developer/mcp-setup/Makefile`. Reproduce the iMac MCP stack on another machine with `cd ~/Developer/mcp-setup && make install`.

## Configurable variables

| Variable | Default | What it controls |
|---|---|---|
| `DEV_DIR` | `$(HOME)/Developer` | Workspace root (where `.vscode/mcp.json` is written) |
| `FS_MCP_SCOPE` | `$(DEV_DIR)` | Path the filesystem MCP server is allowed to touch |

Override on the command line:

```
make install DEV_DIR=$HOME/code FS_MCP_SCOPE=$HOME/code
```

## What `make install` does, in order

1. `check-prereqs` — refuses to start if VS Code, `npx`, or `ollama` are missing.
2. `code-cli` — creates `/usr/local/bin/code` symlink if absent.
3. `cline-ext` — runs `code --install-extension saoudrizwan.claude-dev` (no-op if already installed).
4. `workspace-mcp` — writes `$(DEV_DIR)/.vscode/mcp.json` with filesystem + Playwright entries.
5. `cline-mcp` — writes Cline's MCP config (different key, same data shape).
6. `ollama-agent` — writes `~/Library/LaunchAgents/com.ollama.server.plist`, loads it, verifies `:11434` responds.

Everything writes deterministic content — re-running `make install` produces no diff and no errors.

## Steps to lay down the Makefile from scratch

If you're rebuilding the file (e.g. on a fresh machine):

1. Create the directory:
   ```
   mkdir -p ~/Developer/mcp-setup
   ```

2. Copy the canonical Makefile from this ledger entry: `cp ledger/LEDGER-0001-imac-mcp-setup/playbooks/Makefile ~/Developer/mcp-setup/Makefile`. (Or skip the copy and run `make -C ledger/LEDGER-0001-imac-mcp-setup/playbooks install` directly from a yousirjuan clone.)

3. Test the status target first (it's read-only and won't modify anything):
   ```
   cd ~/Developer/mcp-setup
   make status
   ```

4. If everything reports `✗`, run `make install`. If some pieces report `✓`, `make install` is still safe — it's idempotent.

## Success criteria

```
cd ~/Developer/mcp-setup && make status
```

…shows every section with `✓`:

```
── code CLI ─────────────────────────────
✓ /usr/local/bin/code → /Applications/Visual Studio Code.app/Contents/Resources/app/bin/code
── Cline extension ──────────────────────
✓ installed
── Workspace MCP config ─────────────────
✓ /Users/averygoodman/Developer/.vscode/mcp.json
── Cline MCP config ─────────────────────
✓ /Users/averygoodman/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json
── Ollama LaunchAgent ───────────────────
✓ loaded: <pid>  0  com.ollama.server
── Ollama HTTP ──────────────────────────
✓ responding on :11434
  • gemma4:latest
  • llama3.2:3b
  • gemma2:2b
```

## Undo (full uninstall)

```
cd ~/Developer/mcp-setup
make uninstall
```

This:
- Unloads + deletes the LaunchAgent plist
- Removes `$(DEV_DIR)/.vscode/mcp.json`
- Resets Cline's MCP config to `{ "mcpServers": {} }` (does not delete the file because Cline may have other settings in its globalStorage)
- Removes the `code` CLI symlink
- **Leaves the Cline extension installed** — remove via VS Code's Extensions UI if you want it gone

## Notes and gotchas

- **`launchctl unload` returns non-zero if the plist isn't currently loaded.** The Makefile suppresses that with `2>/dev/null || true` — don't remove that guard, it's why `make install` is idempotent.
- **`heredoc` style isn't used.** The Makefile builds files via `printf` with one-line-per-shell-arg to keep make's `$$` quoting rules sane. Adding new content means adding new `'…'` lines, not pasting multi-line strings.
- **Cross-machine portability is partial.** On Apple Silicon, `/usr/local/bin` is not on PATH by default — Homebrew lives at `/opt/homebrew/bin`. The `code-cli` target would still work but the resulting symlink wouldn't be on PATH. Override needed.

## Related

- All five runbooks describe what each target does in human terms. Start there for understanding, here for execution.
- Pains the Makefile collectively addresses: PAIN-0006, PAIN-0007, PAIN-0008, PAIN-0009, PAIN-0010.
