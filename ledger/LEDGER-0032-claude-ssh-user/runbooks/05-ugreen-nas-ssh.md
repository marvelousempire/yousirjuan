# 05 — UGreen NAS SSH (UGOS Pro)

## Why `admin@nasa.local` keeps saying Permission denied

UGOS SSH uses the **same username and password as the UGOS web UI** — not a fixed `admin` account unless you literally created a user named `admin`.

| Symptom | Likely cause |
|---|---|
| `Permission denied` with password you know is correct | **`NAS_SSH_USER` wrong** in `operator-hosts.env` |
| `Connection closed by 169.254.x.x` | Bonjour/route glitch — try `192.168.8.204` in `NAS_HOST` |
| Works in browser, fails in SSH | **Terminal → Enable SSH** not applied in UGOS |

## Key login works (Mac → NAS) but playbook still failed?

If `ssh abrownsanta@nasa.local` works **with your Mac key**, you only need **sudo password** once — not SSH login password.

The old playbook forced password-only SSH and copied to `/tmp`, which UGOS often rejects. The fixed playbook:

1. Detects your key on `abrownsanta@nasa.local`
2. Uploads the script via **base64 over SSH** (UGOS blocks `scp` writes)
3. Prompts only for **`sudo` password**

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh nas
```

Or one-shot if `~/claude-bootstrap.sh` is already on the NAS:

```bash
PUBKEY=$(tr -d '\n\r' < ~/.ssh/id_ed25519.pub)
ssh -tt abrownsanta@nasa.local \
  "sudo env USER_NAME=claude PUBKEY='$PUBKEY' NOPASSWD_SUDO=0 PLATFORM=linux bash ~/claude-bootstrap.sh"
```

Use the username you type at `https://nasa.local:9999`:

```bash
NAS_HOST=nasa.local
NAS_SSH_USER=your-ugos-web-username    # e.g. abrownsanta — NOT assumed "admin"
NAS_SSH=${NAS_SSH_USER}@${NAS_HOST}
NAS_SSH_PORT=22                        # change if you customized SSH port in UGOS
```

## UGOS checklist (browser)

1. `https://nasa.local:9999` — note the **exact login username**
2. **Control Panel → Terminal** → **Enable SSH service** → **Apply**
3. Optional: change SSH port (then set `NAS_SSH_PORT`)

## Test before the playbook

```bash
ssh -o PubkeyAuthentication=no -o PreferredAuthentications=password \
  YOUR_UGOS_USER@nasa.local
```

If that works, run:

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/install-from-mac.sh nas
```

Enter the **same UGOS password** up to three times per phase (scp, ssh, sudo).

## After lockout from retries

Wait **5–10 minutes**, confirm username in UGOS, then test manual SSH once before re-running the script.

## App storage (separate from SSH)

DGX product photos/backups need an **NFS share** in UGOS (Option A) — see `nephew/plans/0137-ugreen-nas-shared-storage.md`. SSH `claude` is for management keys, not the NFS mount.
