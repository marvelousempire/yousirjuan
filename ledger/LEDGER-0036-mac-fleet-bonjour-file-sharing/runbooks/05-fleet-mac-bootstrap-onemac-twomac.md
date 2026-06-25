# 05 — Bootstrap onemac and twomac from fivemac

## Blocker

fivemac cannot SSH to onemac (`192.168.10.159`) or twomac (`192.168.10.166`) — `Permission denied (publickey)`.

## One-time fix (run ON each peer Mac)

### 1. Copy bootstrap script

From fivemac Terminal:

```bash
scp fivemac.local:Sites/yousirjuan/ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/bootstrap-mac-fleet-ssh.sh ~/
```

Or AirDrop the file from `Sites/yousirjuan/ledger/LEDGER-0036-.../playbooks/`.

### 2. Run bootstrap

On **onemac** and **twomac**:

```bash
bash ~/bootstrap-mac-fleet-ssh.sh
```

This:

- Appends fivemac's SSH public key to `~/.ssh/authorized_keys`
- Runs admin-only File Sharing setup
- Aligns Bonjour Computer Name with LocalHostName

### 3. Re-run from fivemac

```bash
cd ~/Sites/yousirjuan
bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/install-from-fivemac.sh
```

## Rename SMB browse names (optional)

Default onemac advertises as **MacBook Pro**. To show **onemac** in Network:

```bash
sudo bash ledger/LEDGER-0036-mac-fleet-bonjour-file-sharing/playbooks/configure-mac-bonjour-name.sh
# with MAC_BONJOUR_NAME=onemac on onemac, twomac on twomac
```