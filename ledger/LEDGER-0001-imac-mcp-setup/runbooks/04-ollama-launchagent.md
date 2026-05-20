# Runbook 04 — Persistent Ollama via macOS LaunchAgent

**Time:** ~30 seconds
**Reversible:** yes (`launchctl unload` + `rm`)
**Prereqs:** `ollama` CLI binary at `/usr/local/bin/ollama` (independent of whether Ollama.app works)

## Why

On macOS, the normal way to keep Ollama running is the Ollama.app — it lives in the menubar and starts on login. **On macOS Ventura 13.x, the current Ollama.app refuses to launch** (`kLSIncompatibleSystemVersionErr`) because Apple now requires Sonoma or Sequoia. But the standalone `ollama` CLI binary still works fine — only the GUI wrapper is broken.

A macOS LaunchAgent gives us:
- **RunAtLoad** — starts when the user logs in
- **KeepAlive** — auto-restarts if it crashes
- No dependency on the broken .app
- Logs to a known path

This is also the right answer on any headless macOS machine where you don't want a menubar tray.

## Steps

### 1. Stop any session-bound `ollama serve` first

If you previously ran `ollama serve &` from a terminal, kill it so the LaunchAgent can bind `:11434`:

```
pkill -f "ollama serve" 2>/dev/null
```

### 2. Write the LaunchAgent plist

File: `~/Library/LaunchAgents/com.ollama.server.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/averygoodman/Library/Logs/ollama.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/averygoodman/Library/Logs/ollama.log</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin</string>
    </dict>
    <key>ProcessType</key>
    <string>Background</string>
</dict>
</plist>
```

Replace `averygoodman` with the operator username if running on a different account.

### 3. Make sure the log directory exists

```
mkdir -p ~/Library/Logs
```

### 4. Load it

```
launchctl unload ~/Library/LaunchAgents/com.ollama.server.plist 2>/dev/null
launchctl load -w ~/Library/LaunchAgents/com.ollama.server.plist
```

The `-w` flag persists the "enabled" state, so it'll come back after reboot. The `unload || true` line makes the command idempotent — running it twice in a row is safe.

### 5. Verify

```
launchctl list | grep com.ollama.server
```

You should see a line like `12345  0  com.ollama.server` — the middle column is the last exit status (`0` = healthy). If it's `1` or anything else, check the log.

```
curl -s http://localhost:11434/api/tags
```

Should return JSON with the list of pulled models.

## Success criteria

- `launchctl list | grep com.ollama.server` returns a row with exit code 0.
- `curl http://localhost:11434/api/tags` returns `{"models":[...]}`.
- Log file at `~/Library/Logs/ollama.log` contains the `"Listening on 127.0.0.1:11434"` line.

## Daily operation

| Action | Command |
|---|---|
| Stop | `launchctl unload ~/Library/LaunchAgents/com.ollama.server.plist` |
| Start | `launchctl load ~/Library/LaunchAgents/com.ollama.server.plist` |
| Tail logs | `tail -f ~/Library/Logs/ollama.log` |
| List models | `ollama list` |
| Pull a model | `ollama pull qwen2.5-coder:7b` |

## Undo

```
launchctl unload ~/Library/LaunchAgents/com.ollama.server.plist
rm ~/Library/LaunchAgents/com.ollama.server.plist
```

## Notes and gotchas

- **LaunchAgent vs LaunchDaemon.** LaunchAgents run per-user on login. LaunchDaemons run system-wide before login. For a single-user iMac, the Agent is correct. Don't elevate to Daemon unless multiple users need shared Ollama.
- **`launchctl bootstrap` is the modern API.** The classic `launchctl load -w` still works on all currently-supported macOS versions. If you ever target a stripped-down macOS where `load` is removed, switch to `launchctl bootstrap gui/$UID <plist>` and `launchctl bootout gui/$UID <plist>`.
- **`KeepAlive: true` is unconditional.** If Ollama exits cleanly (signal-killed), launchd will restart it. To stop it for real, you must `launchctl unload` the plist, not just `kill` the process.
- **GPU detection.** The Ollama log line `inference compute id=cpu library=cpu` confirms the runner couldn't find a GPU. On Apple Silicon you'd see `id=metal` instead. CPU inference is markedly slower — see [PAIN-0010](../../../pain-journal/PAIN-0010-intel-cpu-no-gpu.md).

## Related

- Makefile target: `ollama-agent`, plus `start`/`stop`/`restart`. See [05-makefile-wrapper.md](05-makefile-wrapper.md).
- Pains that motivated this: [PAIN-0006](../../../pain-journal/PAIN-0006-ollama-app-incompatible.md), [PAIN-0010](../../../pain-journal/PAIN-0010-intel-cpu-no-gpu.md).
