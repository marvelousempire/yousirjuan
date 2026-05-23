# 05 — Verify end-to-end

## Goal

Confirm the drift detector actually reads from GitHub now. The bright-line metric: `failures: 88 → ~0`.

## The verification one-liner

```
ssh vps-godaddy 'sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
  sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -25'
```

## Expected output shape

```json
{
    "ts": "2026-05-22T...Z",
    "total": 88,
    "drift_corrected": 0 OR <small number>,
    "failures": 0 OR <small number>,
    "entries": [
        {
            "repo": "yousirjuan",
            "origin": "85dbe7b1c4...",
            "gitlab": "85dbe7b1c4...",
            "action": "none",
            "result": "ok"
        },
        ...
    ]
}
```

What changed:
- **`origin`** and **`gitlab`** now have real SHAs instead of empty strings.
- **`result`** is `"ok"` (or `"clone-failed"` / `"origin-fetch-failed"` for repos with genuine access issues — at most a handful, not 88).
- **`action`** is `"none"` for in-sync repos, or `"fast-forward-gitlab"` / `"merge-ours-both-remotes"` when drift was actually corrected.

## If something is wrong

| Symptom | Likely cause | Fix |
|---|---|---|
| `failures: 88` still | Token didn't deploy OR script didn't update | Re-run runbook 03 + 04 |
| `failures: 88`, all `clone-failed` | Token has wrong scope | GitHub → revoke + regenerate with `contents:read` + `metadata:read` |
| `failures: ~10`, mixed errors | Some repos archived / renamed / outside org | Drop them from `/opt/yousirjuan-sync/tracked-repos.txt` |
| JSON parse error | New JSON bug in sync-and-drift.sh | Capture the raw file (`sudo cat /var/lib/yousirjuan/dual-push-drift-report.json`) and file a fix PR against LEDGER-0024 |
| `failures: 0` but `total` is wrong | `tracked-repos.txt` out of date | Update the tracked list to match marvelousempire's actual repos |

## Status flip

When the verification passes:

1. Edit the parent ticket's frontmatter: `status: shipped`, `closed: YYYY-MM-DD`.
2. Edit the parent ticket's "Outcome" section to describe what shipped.
3. Edit the ledger index row to reflect `shipped`.
4. Land all three in a follow-up commit (or amend if the ship-PR isn't merged yet).

## Success criteria (canonical)

`failures` field of `/var/lib/yousirjuan/dual-push-drift-report.json` < 5 on vps-godaddy, and `entries[*].origin` is a non-empty SHA for the bulk of the array.

## Undo

To return to the pre-LEDGER-0025 state, see runbooks 03 and 04 Undo sections in sequence.
