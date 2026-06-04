# 06 — NAS NFS for DGX (`search-my-engine`)

Folder **`/volume1/search-my-engine`** already exists on the NAS (SMB share configured).
DGX **`192.168.8.249`** can ping **`nasa.local`** over IPv4. NFS export is the remaining step.

## Phase A — UGOS (automated or browser)

### Option 1 — One command from ONEMAC (preferred)

Uses the UGOS web API (same login as `https://nasa.local:9999`). Prompts for your UGOS password once, enables NFS, adds the export rule, then mounts DGX.

```bash
cd ~/Developer/yousirjuan
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/setup-nas-dgx-storage.sh
```

Non-interactive (password in env, not git):

```bash
NAS_PASSWORD='…' bash ledger/LEDGER-0032-claude-ssh-user/playbooks/setup-nas-dgx-storage.sh
```

If login says **too many failed logins**, wait ~5 minutes (failed API tests trigger UGOS lockout), then re-run.

### Option 2 — UGOS browser (~3 minutes)

Open **`https://nasa.local:9999`** as **`abrownsanta`**.

1. **Control Panel → File Service → NFS**
   - Enable **NFS service** → **Apply**
2. **File Manager → Shared folder → `search-my-engine`**
   - Right-click → **Properties** → **NFS permissions** → **Add**
   - **Client / host:** `192.168.8.0/24` (whole inner LAN — includes DGX `.249`)
   - **Privilege:** Read/Write
   - **Squash:** Map all users to admin (UGOS wording: log all users as admin)
   - **Save / Apply**

Optional second rule for Mac 10GbE direct link later: `10.77.0.0/30`.

## Phase B — Mount on DGX (from ONEMAC Terminal)

After NFS rule is saved:

```bash
cd ~/Developer/yousirjuan
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/mount-nas-on-dgx.sh
```

Wait for export:

```bash
bash ledger/LEDGER-0032-claude-ssh-user/playbooks/mount-nas-on-dgx.sh --wait
```

## Verify

```bash
showmount -e nasa.local
# expect: /volume1/search-my-engine  192.168.8.0/24

ssh abrownsanta@nephew-spark 'mount | grep /mnt/nas && touch /mnt/nas/.dgxprobe && rm /mnt/nas/.dgxprobe && echo dgx-rw-ok'
```

## Export path reference

| Item | Value |
|------|--------|
| NAS | `nasa.local` / `192.168.8.204` |
| Export | `/volume1/search-my-engine` |
| DGX mount | `/mnt/nas` |
| DGX user | `abrownsanta` (passwordless sudo) |
