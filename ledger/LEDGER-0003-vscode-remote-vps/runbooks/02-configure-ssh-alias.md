# Runbook 02 — Configure the `vps-godaddy` SSH alias

**Time:** ~10 seconds
**Reversible:** yes (delete the appended stanza)
**Prereqs:** existing `~/.ssh/id_ed25519` key whose public key is already in `abrownsanta@vps-godaddy`'s `~/.ssh/authorized_keys` (otherwise stop here and copy the pubkey first — see "Auth handoff" below)

## Why

A friendly SSH alias collapses `ssh -p 2222 -i ~/.ssh/id_ed25519 abrownsanta@72.167.151.251` to just `ssh vps-godaddy`. VS Code Remote-SSH's host picker reads `~/.ssh/config` and shows every `Host` block by name — so once the alias exists, "Remote-SSH: Connect to Host…" lists `vps-godaddy` and one click connects.

The non-obvious detail is **port 2222**, not 22. The VPS's `sshd` is on a non-standard port; trying port 22 (the default) returns "Connection refused" with no useful diagnostics. The alias bakes in the right port so neither you nor a future agent has to remember.

## Steps

### 1. Confirm the key fingerprint exists locally

```bash
ssh-keygen -lf ~/.ssh/id_ed25519.pub
```

…should print `256 SHA256:... mac-... (ED25519)`. If the key file doesn't exist, generate one (`ssh-keygen -t ed25519`) and arrange for its `.pub` content to be appended to `abrownsanta@vps-godaddy:~/.ssh/authorized_keys` — that's the **auth handoff** below.

### 2. Append the canonical Host stanza to `~/.ssh/config`

The canonical content lives at [`artifacts/ssh-config-snippet.txt`](../artifacts/ssh-config-snippet.txt). To install it:

```bash
cat ~/Developer/yousirjuan/ledger/LEDGER-0003-vscode-remote-vps/artifacts/ssh-config-snippet.txt >> ~/.ssh/config
```

Or, if the snippet isn't reachable, paste this exact block at the end of `~/.ssh/config`:

```
Host vps-godaddy
    HostName 72.167.151.251
    User abrownsanta
    Port 2222
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
    AddKeysToAgent yes
    UseKeychain yes
    ServerAliveInterval 60
    ServerAliveCountMax 3
```

### 3. Verify the alias resolves correctly

```bash
ssh -G vps-godaddy | grep -E "^(hostname|user|port|identityfile)"
```

Should print:

```
hostname 72.167.151.251
user abrownsanta
port 2222
identityfile ~/.ssh/id_ed25519
```

If any value is wrong, the stanza didn't get appended cleanly — re-check `~/.ssh/config`.

### 4. Test the connection non-interactively

```bash
ssh -o ConnectTimeout=5 vps-godaddy 'echo ok && hostname && whoami'
```

Expected output:

```
ok
<vps-hostname>
abrownsanta
```

If you get `Permission denied (publickey)`, see [runbook 04](04-troubleshoot-refused-connections.md).
If you get `Connection refused`, see [runbook 04](04-troubleshoot-refused-connections.md).
If it asks for a passphrase, **enter it once**. macOS Keychain (`UseKeychain yes` in the stanza) caches it for the rest of the login session.

## Auth handoff — if the pubkey isn't authorized server-side yet

If [runbook 04](04-troubleshoot-refused-connections.md)'s diagnostic shows the server **doesn't accept** your key (different signal than the BatchMode/Keychain pattern), you need to add your local public key to the server's `~/.ssh/authorized_keys`. The chicken-and-egg problem: you can't SSH to do it. Three usual paths:

1. **Console / out-of-band access** — log into the VPS via GoDaddy's web console, paste the contents of `~/.ssh/id_ed25519.pub` (read locally) into `~abrownsanta/.ssh/authorized_keys` on the server.
2. **An already-authorized machine acts as a bastion** — `ssh existing-machine 'cat >> ~/.ssh/authorized_keys' < ~/.ssh/id_ed25519.pub` while connected to a machine that already works.
3. **ssh-copy-id** — `ssh-copy-id -p 2222 abrownsanta@72.167.151.251` works if the server still accepts password auth (it probably doesn't; `PasswordAuthentication no` is the safe default the VPS likely uses).

For the originating iMac in this session, the key was already authorized — verified by `ssh -v` showing "Server accepts key" before the BatchMode-related "Permission denied" red herring (see runbook 04).

## Success criteria

- `ssh -G vps-godaddy` prints the four expected fields with correct values.
- `ssh vps-godaddy 'echo ok'` prints `ok` and exits 0 (after at most one passphrase prompt).
- `~/.ssh/config` opened in an editor shows the `Host vps-godaddy` block.

## Undo

Remove the `Host vps-godaddy` stanza from `~/.ssh/config`. With `python3` (preserves the rest of the file):

```bash
python3 -c "
import re, sys
p = '$HOME/.ssh/config'
s = open(p).read()
# Drop the canonical alias block + its leading comment if present.
s = re.sub(r'\n(# yousirjuan VPS.*?\n)?Host vps-godaddy\n(    .+\n)+', '\n', s)
open(p,'w').write(s)
print('removed Host vps-godaddy stanza')
"
```

## Notes and gotchas

- **Port 2222 is non-standard.** Some corporate networks block outbound 2222 even though they allow 22. If `nc -z 72.167.151.251 2222` fails from a particular network, that's a network-layer block, not a server problem.
- **`IdentitiesOnly yes` is important.** Without it, SSH tries every key in `~/.ssh/` and may trigger a server-side rate limit before reaching `id_ed25519`. With it, only the named key is offered.
- **`UseKeychain yes` is macOS-only.** On Linux, replace with `AddKeysToAgent yes` alone and use `ssh-add ~/.ssh/id_ed25519` once per login session.
- **Keep the stanza idempotent.** If you re-run the install playbook, it checks for the exact block before appending — running twice doesn't double the entry. The duplicate-detection regex is in [`playbooks/install.sh`](../playbooks/install.sh).

## Related

- Previous: [01-install-remote-ssh-extension.md](01-install-remote-ssh-extension.md) — install Remote-SSH first.
- Next: [03-connect-from-vs-code.md](03-connect-from-vs-code.md) — open the remote VS Code window.
- Troubleshooting: [04-troubleshoot-refused-connections.md](04-troubleshoot-refused-connections.md).
- Canonical artifact: [`artifacts/ssh-config-snippet.txt`](../artifacts/ssh-config-snippet.txt).
