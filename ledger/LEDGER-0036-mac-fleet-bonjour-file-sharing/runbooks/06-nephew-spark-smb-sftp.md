# 06 — nephew-spark SMB + SFTP for Mac Finder

## Services on DGX (192.168.10.205)

| Protocol | Port | User | Use |
|----------|------|------|-----|
| SSH / SFTP | 22 | abrownsanta | Shell, Finder SFTP (`⌘K`) |
| SMB | 445 | abrownsanta | Finder drag-and-drop |

## SMB shares

| Share | Path on DGX |
|-------|-------------|
| `Developer` | `/home/abrownsanta/Developer` |
| `abrownsanta` | home directory (via `[homes]`) |

Guest access: **off**. Valid user: `abrownsanta` only.

## Initial Samba deploy (once)

From fivemac with SSH to nephew-spark:

```bash
# Samba config lives on DGX at /etc/samba/conf.d/nephew-spark.conf
# Deploy script: see nephew repo or re-run fix-nephew-spark-mdns + smbpasswd
ssh nephew-spark 'sudo testparm -s | grep -A6 "\[Developer\]"'
```

Set SMB password (first time):

```bash
ssh nephew-spark 'sudo smbpasswd -a abrownsanta'
# Store in fivemac Keychain:
security add-generic-password -a abrownsanta -s nephew-spark-smb -w
```

## SSH config (fivemac)

```
Host nephew-spark dgx
    HostName nephew-spark.local
    User abrownsanta
    IdentityFile ~/.ssh/id_ed25519_nephew_spark
```

## Not a Mac

nephew-spark will never appear as a Mac icon. It appears in Network as **nephew-spark** once Samba + avahi are correct.