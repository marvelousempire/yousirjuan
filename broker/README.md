# yousirjuan-broker

> **Capability-based agent broker.** OpenClaw runs in a Docker container with no
> host access. To take any action on the host (open a URL, take a screenshot,
> read a whitelisted file), it must SSH to a restricted user that runs the
> broker. The broker has a tiny verb vocabulary that you control. Anything
> outside the vocabulary is rejected and logged.
>
> Avery's metaphor: **the prisoner has a phone that only calls specific numbers.**

## Architecture

```
┌──────── HOST (your Mac / Linux box) ───────┐
│                                            │
│  user: yousirjuan-agent                    │
│   home: /home/yousirjuan-agent (or ~)      │
│   shell: /usr/local/bin/yousirjuan-broker  │
│   authorized_keys has ForceCommand=broker  │
│                                            │
│  /usr/local/bin/yousirjuan-broker          │
│   ↳ verbs/                                 │
│      • open-url.sh                         │
│      • screenshot.sh                       │
│      • type-text.sh                        │
│      • read-file.sh    (allowlist-checked) │
│      • ...                                 │
│                                            │
│  /var/log/yousirjuan-broker.log            │
│  (every action logged with timestamp+verb) │
│                                            │
└────────────────────▲───────────────────────┘
                     │ SSH (key-only, ForceCommand)
                     │
┌────────────────────┴───────────────────────┐
│  CONTAINER (openclaw-router)               │
│                                            │
│  OpenClaw                                  │
│   wants to open Safari →                   │
│   ssh yousirjuan-agent@host "open-url URL" │
│                                            │
│  CANNOT do anything else to the host.      │
└────────────────────────────────────────────┘
```

## Status — Phase 2.5 scaffold (wiring not complete yet)

This directory contains the **structure + design** for the broker. Full
wiring lands when we activate Docker mode for OpenClaw end-to-end.

What's here today:

| File | Status | Purpose |
|------|--------|---------|
| `README.md` (this) | ✅ design | Architecture + intent |
| `yousirjuan-broker` | ✅ stub | Main dispatcher script |
| `verbs/open-url.sh` | ✅ stub | Sample verb: open a URL in default browser |
| `verbs/screenshot.sh` | ✅ stub | Sample verb: take a screenshot to stdout |
| `verbs/type-text.sh` | ✅ stub | Sample verb: type text via osascript (macOS) |
| `verbs/read-file.sh` | ✅ stub | Sample verb: read from allowlisted paths only |
| `policy.example.yaml` | ✅ stub | Per-verb rate limits + allowlists |
| `install.sh` | 🔜 to-do | Provisions yousirjuan-agent user + SSH key + authorized_keys |
| `audit-report.sh` | 🔜 to-do | Tail / summarize the broker log |

## Why SSH (not Unix socket / HTTP)

- **Universal** — works the same on Mac and Linux
- **Auditable** — sshd logs every connection; broker logs every verb
- **Battle-tested auth** — key-only, fail2ban-protected, no novel attack surface
- **Trivially revoked** — `rm authorized_keys` and the prisoner is unplugged
- **Native ForceCommand** — sshd refuses to run anything else, even if
  someone tampers with the broker script

## Vocabulary (proposed v1)

| Verb | What it does | Allowlist? | Rate limit |
|---|---|---|---|
| `open-url <url>` | Opens URL in default browser | URL must match a regex set in policy | 30/min |
| `screenshot` | `screencapture - / scrot -` to stdout (raw image) | none | 6/min |
| `type-text <text>` | Sends keystrokes to frontmost app | text length ≤ 1000 chars | 30/min |
| `keystroke <combo>` | Sends key combo (e.g. cmd+space) | combo must be in policy.allowed_combos | 30/min |
| `read-file <path>` | Reads + returns file contents | path must match an allowlist glob | 60/min |
| `notify <title> <body>` | Posts a macOS / Linux notification | title/body length limits | 12/min |
| `clipboard-write <text>` | Writes to clipboard | length ≤ 4096 | 30/min |
| `clipboard-read` | Reads clipboard contents | none | 30/min |
| `run-shortcut <name>` | macOS Shortcuts app: runs a named shortcut | name must be in policy.allowed_shortcuts | 12/min |

Anything not in this list → broker exits 1 + logs the rejected attempt.

## Setup (to be implemented)

```bash
# On the host (Mac or Linux):
sudo bash broker/install.sh
# → creates user `yousirjuan-agent`
# → installs broker + verbs to /usr/local/bin/
# → creates /var/log/yousirjuan-broker.log
# → asks for the container's public key, adds to authorized_keys with ForceCommand
# → runs first-time policy review

# In the container (openclaw-router):
# Mount the SSH private key, set BROKER_HOST + BROKER_USER in .env, restart.
```

## Hardening notes

- The broker user has **no shell** and **no sudo**. The ForceCommand IS its shell.
- All verbs run as the broker user — meaning they have only that user's permissions. You decide which files / apps that user can touch.
- The broker user's `~/.ssh/authorized_keys` is the entire access surface.
- For multi-host setups (Mac + M1 + Jetson), each host runs its own broker. The container picks which host to talk to per task.
- Log everything. `tail -f /var/log/yousirjuan-broker.log` is your real-time view of every action the agent attempts.
- Rate limits via `flock` + counter file in `/var/lib/yousirjuan-broker/`.

## Future: per-verb permission prompts

For high-risk verbs (file write, app installs, etc.) we can add a
notification-prompt mode where the broker sends a macOS notification asking
the human to approve the action before it runs. Inspired by browser
extension permission prompts.

## See also

- [`docs/architecture.md`](../docs/architecture.md) — overall stack
- [`openclaw-router/`](../openclaw-router/) — the OpenClaw container that talks to this broker
