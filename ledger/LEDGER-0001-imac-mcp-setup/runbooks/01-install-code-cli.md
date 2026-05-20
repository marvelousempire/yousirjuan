# Runbook 01 — Install the `code` CLI on PATH

**Time:** ~10 seconds
**Reversible:** yes (`rm` the symlink)
**Prereqs:** VS Code installed at `/Applications/Visual Studio Code.app`

## Why

Without this, you cannot:
- `code /path/to/project` from a terminal
- `code --install-extension <id>` (needed by the Cline runbook and by the Makefile)
- `code --list-extensions` for status checks

VS Code ships the CLI binary inside its app bundle, but does not put it on PATH by default. The official method is in-app: ⇧⌘P → **Shell Command: Install 'code' command in PATH**. The shell-friendly method is a symlink, which is what this runbook does.

## Steps

1. Verify VS Code is installed:
   ```
   ls -d "/Applications/Visual Studio Code.app"
   ```
   If missing, install VS Code first.

2. Confirm the bundled CLI exists:
   ```
   ls -l "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
   ```

3. Confirm `/usr/local/bin` is writable without sudo:
   ```
   test -w /usr/local/bin && echo OK
   ```
   On Apple Silicon Macs where Homebrew lives at `/opt/homebrew/bin`, target that path instead and adjust your PATH accordingly.

4. Create the symlink:
   ```
   ln -s "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code
   ```

5. Verify:
   ```
   code --version
   ```
   Expected: a version string ≥ `1.102` (MCP went GA in 1.102; we observed `1.120.0` on this iMac on 2026-05-19).

## Success criteria

- `code --version` prints a version (not "command not found").
- `readlink /usr/local/bin/code` resolves to the VS Code app bundle path.

## Undo

```
rm /usr/local/bin/code
```

## Related

- The Makefile target `code-cli` performs this idempotently. See [05-makefile-wrapper.md](05-makefile-wrapper.md).
- Pain that motivated this: [PAIN-0007](../../../pain-journal/PAIN-0007-code-cli-not-on-path.md).
