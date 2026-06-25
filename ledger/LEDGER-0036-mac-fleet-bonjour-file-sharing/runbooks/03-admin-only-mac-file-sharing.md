# 03 — Admin-only File Sharing on a Mac

## Goal

Only the **admin user home folder** is shared over SMB. No guest access. No whole-disk or Public-folder shares.

## Run on each Mac (fivemac, onemac, twomac)

```bash
cd ~/Sites/yousirjuan
sudo MAC_ADMIN_USER=averygoodman \
  bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/configure-mac-admin-file-sharing.sh
```

## What it does

1. Verifies user is in group `admin`
2. Enables SMB share on `/Users/<admin>` only
3. Removes other share points (Public, Macintosh HD, other users)
4. Sets `guestAccess` false globally
5. Keeps **Remote Login** on (for SFTP over SSH)

## Verify

```bash
sharing -l -f json | python3 -m json.tool
```

Expect a single share, `"smb_guest_access": 0`.

## Connect from another Mac

```
⌘K → smb://averygoodman@onemac.local
```

Sign in with that Mac's admin password. Check **Remember password** + Keychain.