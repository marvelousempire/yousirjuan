# PAIN-0007 — `code` CLI not on PATH after VS Code install

**Logged:** 2026-05-19
**Surfaced during:** [iMac MCP setup session](../docs/sessions/2026-05-19-mcp-setup/journal.md)
**Severity:** low — easily fixed, but breaks automation until fixed.

## The pain

After installing VS Code via the standard `.dmg` drag-to-Applications method, the `code` command is **not** on PATH. Operators get `command not found: code` from any terminal.

The shim is buried inside the .app bundle at `/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code` — but nothing on the macOS install path puts it on PATH automatically.

VS Code's official workaround is "open the app, ⇧⌘P, run **Shell Command: Install 'code' command in PATH**." That requires the operator to know the workaround exists.

## Why it matters

- **Automation scripts break.** `code --install-extension <id>` is the standard way to install extensions from a Makefile or CI step. If `code` isn't on PATH, none of that works.
- **Terminal-driven workflows break.** `code .` to open a project, `code -d a.txt b.txt` to diff — staples of a CLI-first workflow.
- **The fix requires GUI interaction.** Even though the workaround is one menu pick, it can't happen in a headless install or a fully scripted setup unless someone does it by hand once.

## Why this matters extra for yousirjuan

Several flows in this project rely on terminal commands invoking VS Code:
- The MCP installer (this session) needs `code --install-extension`.
- Future "open this project in VS Code" agent actions need `code`.
- Any LaunchAgent / scheduler that drives VS Code needs the CLI.

## What worked

A symlink:

```
ln -s "/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code" /usr/local/bin/code
```

`/usr/local/bin` is already on PATH on this iMac and is user-writable (no sudo). On Apple Silicon Macs where Homebrew owns `/opt/homebrew/bin`, that's the more idiomatic target.

→ See [runbook 01](../docs/sessions/2026-05-19-mcp-setup/runbooks/01-install-code-cli.md).

## Potential feature

**"yousirjuan workstation bootstrap" target.** A small idempotent script that ensures `code`, `ollama`, `npx`, and the other CLI tools yousirjuan relies on are all on PATH. Pair with a `yousirjuan doctor` command that diagnoses environment gaps and offers to fix them.

This is the kind of friction that erodes operator trust the first time it happens, and that any new joiner will hit. Worth fixing once, durably.

## Where the fix lives

- Runbook: [01-install-code-cli.md](../docs/sessions/2026-05-19-mcp-setup/runbooks/01-install-code-cli.md)
- Reproducible target: `make code-cli` in [the session Makefile](../docs/sessions/2026-05-19-mcp-setup/artifacts/Makefile)
