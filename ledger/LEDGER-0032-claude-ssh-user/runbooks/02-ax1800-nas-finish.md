# 02 — Slate (AX1800) + NAS

## Slate — GL-AX1800 @ `192.168.9.1`

| IP | Device | SSH |
|---|---|---|
| **`192.168.9.1`** | **GL-AX1800 (Slate)** on Flint WAN subnet | Port 22 — login **`root`** |
| `192.168.8.1` | **Flint 2** inner gateway | `claude` or `root` — UI login **`admin`** |
| `192.168.0.1` | **ISP gateway** | Not GL.iNet — no `claude` setup |

### UI

1. **`https://192.168.9.1`** — log in as **`root`**.
2. **System → Security → SSH** → **Enable SSH** ON → **Apply** (Access Control).
3. Prefer **Remote SSH Access** OFF on WAN.

### From Mac (script)

```bash
read -s SLATE_PASSWORD; echo
SLATE_PASSWORD="$SLATE_PASSWORD" bash ledger/LEDGER-0032-claude-ssh-user/playbooks/provision-ax1800-slate.sh
```

### On-router (when already `root@GL-AXT1800`)

Run the `PUBKEY=…` block from [`docs/family-fleet-ssh-claude.md`](../../../docs/family-fleet-ssh-claude.md), then `exit` and from Mac: `ssh claude@192.168.9.1 id`.

**Important:** Run provisioning on the **Mac** (`nivram@…`), not inside the router shell, unless using the on-router block above.

## NAS — UGreen @ `192.168.8.x`

1. `https://192.168.8.x:9999` → enable SSH.
2. Create user `claude` or add pubkey to admin.
3. `NAS_SSH=claude@192.168.8.x bash …/install-from-mac.sh nas`
