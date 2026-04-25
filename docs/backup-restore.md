# Backup + restore

What's at risk if your Mac/VPS dies, and how to protect against it.

## What lives where

| Data | Location | Replaceable? |
|---|---|---|
| Open WebUI: chat history, accounts, prompts, knowledge bases, uploaded files | Docker volume `open-webui` (`/var/lib/docker/volumes/open-webui/_data` on host) | **No** — irreplaceable user data |
| OpenClaw: agent config, sessions, workspace, channel configs | `~/.openclaw/` | **No** — config + auth tokens |
| Ollama models | `$OLLAMA_MODELS` directory (default `~/.ollama/models`) | Yes — re-pullable, just slow |
| nginx vhost + Let's Encrypt cert | `/etc/nginx/sites-*` + `/etc/letsencrypt/` | Yes — re-create via `vps/apply-vps-config.sh` (cert re-issued) |
| iptables rules | Kernel + `/etc/iptables/rules.v4` | Yes — re-apply via `vps/iptables-public-lockdown.sh` |
| Docker images | `/var/lib/docker/` | Yes — re-pull |

The two **irreplaceable** items are Open WebUI's volume and OpenClaw's config — that's what `backup.sh` captures.

## Make a backup

```bash
# default location: ~/Documents/private-ai-backups/private-ai-YYYYMMDD-HHMMSS.tgz
bash tools/backup.sh

# or to an external drive:
bash tools/backup.sh /Volumes/USB/yousirjuan-backup.tgz
```

Safe to run while everything is live (volume is read via a transient alpine container with read-only mount).

The tarball contains:
- `openclaw/` — copy of `~/.openclaw` (minus logs)
- `open-webui.tar.gz` — full Open WebUI volume contents
- `manifest.txt` — versions, model list, hostname, timestamp

Typical size: 100 MB – 5 GB depending on how many chats / docs you've accumulated.

## Restore on a fresh box

Pre-condition: the new box already has the stack installed (`bash bootstrap.sh` already ran).

```bash
bash tools/restore.sh ~/Documents/private-ai-backups/private-ai-20260424-170000.tgz
```

The script:
1. Extracts to a temp dir, shows you the manifest
2. Asks for confirmation
3. Backs up the current state first (just in case)
4. Stops the OpenClaw gateway, replaces `~/.openclaw`, restarts gateway
5. Stops Open WebUI container, replaces volume contents, restarts container
6. Prints `ollama pull <model>` commands for whatever models the source machine had

Models are NOT in the backup — you re-pull them after restore.

## Off-site backup strategy (recommended for family office)

Backups are useless if they live on the same disk that's about to die. Set up off-site copies.

### Option A: Pull to your laptop on a schedule

On your Mac, daily cron job:

```bash
# Edit your crontab:  crontab -e
# Add:
0 3 * * * ssh vps-godaddy 'bash /path/to/yousirjuan/tools/backup.sh /tmp/yousirjuan-daily.tgz' && \
          rsync -av vps-godaddy:/tmp/yousirjuan-daily.tgz ~/Documents/yousirjuan-backups/$(date +\%Y\%m\%d).tgz
```

### Option B: Push to S3 / B2 / etc.

```bash
# (one-time install) brew install aws-cli  OR  brew install b2-cli
# Then in your daily cron:
bash tools/backup.sh /tmp/today.tgz
gpg --symmetric --cipher-algo AES256 /tmp/today.tgz   # encrypt with passphrase
aws s3 cp /tmp/today.tgz.gpg s3://yousirjuan-backups/$(date +%Y%m%d).tgz.gpg
rm /tmp/today.tgz /tmp/today.tgz.gpg
```

### Option C: Use Tailscale to push to a NAS at home

If you have a Synology / TrueNAS / etc. on your tailnet, just `rsync` over the tunnel — encrypted, free, no third party.

```bash
bash tools/backup.sh /tmp/today.tgz
rsync -av /tmp/today.tgz nas-tailnet-name:/volume1/yousirjuan-backups/$(date +%Y%m%d).tgz
```

## How long to keep backups

Reasonable retention: **30 daily + 12 monthly + 5 yearly** ("grandfather-father-son"). For Open WebUI chat history this is way more than enough.

## Encrypt your backups

The tarball contains plaintext chat content. **Encrypt before storing off-site** unless the destination is in your trust boundary (your own NAS over Tailscale).

```bash
# Encrypt with a passphrase you remember
gpg --symmetric --cipher-algo AES256 backup.tgz   # → backup.tgz.gpg

# Decrypt later
gpg --decrypt backup.tgz.gpg > backup.tgz
```

## Test your restores

Backups you've never restored aren't backups. Once a quarter:

1. Spin up a throwaway VPS / VM
2. Clone this repo, run `bootstrap.sh`
3. Run `tools/restore.sh /path/to/backup.tgz`
4. Open the Open WebUI URL, sign in, verify your chats are there
5. Tear down the test box

If restore fails, fix the script + add a regression test before you actually need the backup.
