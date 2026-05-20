# Runbook 04 — Diagnose "Connection refused" / "Permission denied" on `vps-godaddy`

**Time:** ~2 minutes to triage with the commands below
**Reversible:** read-only diagnosis — none of these commands change state
**Prereqs:** none beyond `ssh`, `nc`, and `ping` (all default on macOS / Linux)

## Why

"Refused" is two different bugs in a trench coat:

- **Network-layer refused:** the TCP connection itself fails (`Connection refused` or `Connection timed out`). The server didn't even get a chance to talk to your SSH client.
- **Auth-layer refused:** the TCP connection succeeded, the SSH handshake started, but authentication failed (`Permission denied (publickey)` / `Permission denied (password)`).

Each has a different fix path. The first 90 seconds of any "I can't SSH" debugging should be spent figuring out which one is happening. This runbook is that 90 seconds, codified.

Encoded from real session evidence (2026-05-20): the operator's iMac saw "Connection refused" because port 22 is closed on the VPS; port 2222 is the real SSH port. Then `ssh -v` showed "Server accepts key … Permission denied (publickey)" — which is **not** an actual authorization failure; it's the signature of `BatchMode=yes` suppressing the macOS Keychain passphrase prompt. Same English error string, two completely different layers.

## The 90-second triage script

```bash
HOST=72.167.151.251
PORT=2222
USER=abrownsanta
KEY=~/.ssh/id_ed25519
echo "─ layer 1: ICMP ─"; ping -c 1 -W 2000 "$HOST" 2>&1 | head -3
echo "─ layer 2: TCP on $PORT ─"; nc -z -G 5 -v "$HOST" "$PORT" 2>&1 | head -2
echo "─ layer 2: TCP on 22 (does default port work?) ─"; nc -z -G 5 -v "$HOST" 22 2>&1 | head -2
echo "─ layer 3: SSH banner ─"; nc -G 5 "$HOST" "$PORT" 2>&1 | head -1
echo "─ layer 4: SSH alias resolution ─"; ssh -G vps-godaddy 2>&1 | grep -E "^(hostname|user|port|identityfile)"
echo "─ layer 5: SSH agent identities ─"; ssh-add -l 2>&1
echo "─ layer 6: SSH verbose handshake (interactive — passphrase prompt may appear) ─"
ssh -o ConnectTimeout=5 -i "$KEY" -p "$PORT" -v "$USER@$HOST" 'echo ok' 2>&1 | \
  grep -E "Offering|Server accepts|Authenticated|Permission denied|debug1: Connection" | head -10
```

Pipe all six results into your reasoning. The pattern in the output tells you which layer is broken.

## Common patterns and their fixes

### Pattern A — ICMP works, both TCP ports refused

```
─ layer 1: ICMP ─
64 bytes from 72.167.151.251 ...
─ layer 2: TCP on 2222 ─
nc: ... port 2222 ... Connection refused
─ layer 2: TCP on 22 ─
nc: ... port 22 ... Connection refused
```

**Diagnosis:** The host is up but no SSH daemon is listening on either port. Possible: VPS rebooted into a state where `sshd` failed to start, OR firewall is dropping everything except 80/443. Don't try to reauth — fix the server.

**Fix:** Check the VPS's web console or out-of-band access; `systemctl status sshd` and `iptables -L -n` are the diagnostics.

### Pattern B — Port 22 refused, port 2222 succeeds (the operator's actual case 2026-05-20)

```
─ layer 2: TCP on 2222 ─
Connection to 72.167.151.251 port 2222 [tcp/rockwell-csp2] succeeded!
─ layer 2: TCP on 22 ─
nc: ... port 22 ... Connection refused
```

**Diagnosis:** SSH daemon listens on a non-standard port. The default `ssh user@host` invocation tries 22 and fails. This is **not** an auth problem — it's a port configuration mismatch.

**Fix:** Use `Port 2222` in the `~/.ssh/config` alias (see [runbook 02](02-configure-ssh-alias.md)), or pass `-p 2222` on every CLI invocation. The canonical alias bakes the right port in.

### Pattern C — TCP succeeds, banner shows, "Server accepts key" then "Permission denied (publickey)"

```
─ layer 3: SSH banner ─
SSH-2.0-OpenSSH_9.x Ubuntu-...
─ layer 6: SSH verbose handshake ─
debug1: Offering public key: /Users/averygoodman/.ssh/id_ed25519
debug1: Server accepts key: /Users/averygoodman/.ssh/id_ed25519
abrownsanta@72.167.151.251: Permission denied (publickey).
```

**Diagnosis (counterintuitive):** Despite the error string saying "publickey," **the server already accepted the key**. The failure is at the SIGNING step — the SSH client couldn't sign the server's challenge with the private key. On macOS, this almost always means:

- The private key has a passphrase
- The passphrase isn't in ssh-agent yet
- The current SSH invocation has `BatchMode=yes` set (often by VS Code Remote-SSH or by `-o BatchMode=yes` on the command line), which suppresses the Keychain prompt
- The signing operation silently fails → server gets no signature → "permission denied"

**Fix:** Drop `-o BatchMode=yes` and re-run. macOS will pop a Keychain dialog for the passphrase; enter it once and tick "Always allow." The key gets unlocked and cached in ssh-agent for the rest of the login session. Verify with `ssh-add -l` — it should now list the key. After that, even BatchMode connections work for the rest of the session.

Permanent fix (avoid the prompt forever):

```bash
ssh-add --apple-use-keychain ~/.ssh/id_ed25519
```

…enters the passphrase once, stores it in Keychain, and any future SSH client (BatchMode or not) finds it automatically via the macOS keychain helper.

### Pattern D — TCP succeeds, "Server accepts key" never appears, just "Permission denied"

```
debug1: Offering public key: /Users/averygoodman/.ssh/id_ed25519
debug1: Authentications that can continue: publickey
abrownsanta@72.167.151.251: Permission denied (publickey).
```

(No `Server accepts key:` line.)

**Diagnosis:** This IS a real authorization failure. The server doesn't have your public key in `authorized_keys`. Different from pattern C — here the server rejects the pubkey before reaching the signing step.

**Fix:** See [runbook 02 — Auth handoff section](02-configure-ssh-alias.md#auth-handoff--if-the-pubkey-isnt-authorized-server-side-yet). You need to add `~/.ssh/id_ed25519.pub` to `abrownsanta@vps-godaddy:~/.ssh/authorized_keys` via console or a bastion.

### Pattern E — VS Code-specific "refused" with no useful CLI symptom

You run `ssh vps-godaddy 'echo ok'` from a terminal and it works. You open VS Code Remote-SSH and it says "could not establish connection" / "process exited with code 255."

**Diagnosis:** VS Code's SSH client and the system SSH client disagree on something. Most common: `remote.SSH.useLocalServer` is `false` (forces VS Code's built-in SSH which misses Keychain), or `remote.SSH.configFile` is set to a path that doesn't have the `vps-godaddy` alias.

**Fix:** In VS Code, **Cmd+,** → search for "remote.SSH" → check:
- `Remote.SSH: Use Local Server` should be `true` (checked).
- `Remote.SSH: Config File` should be empty (uses `~/.ssh/config`) OR explicitly set to `~/.ssh/config`.

Also see VS Code's **Output → Remote-SSH** dropdown for the exact ssh command line VS Code tried, with the exact exit reason.

### Pattern F — fail2ban banned you

Connection refused even though port 2222 was working 10 minutes ago and you've been debugging. The server's fail2ban watches for repeated failed auth attempts and bans the source IP for 24 hours.

**Diagnosis:** Multiple recent `Permission denied` failures from this IP probably triggered the ban. From a different network (cellular hotspot, friend's WiFi), `nc -z $HOST 2222` would still succeed — confirming it's IP-specific.

**Fix:** Either wait out the ban (24h default), get on a different network temporarily, OR (if you have console access) unban your IP server-side:

```bash
# On the VPS (via console / different machine):
sudo fail2ban-client status sshd
sudo fail2ban-client set sshd unbanip <YOUR_PUBLIC_IP>
```

This is why the runbooks emphasize getting the alias right the FIRST time and not iterating with many `ssh -i wrong-key.pub …` attempts — each failure brings you closer to a ban.

## Success criteria for "fixed"

Whatever pattern matched, the fix is verified when:

```bash
ssh -o ConnectTimeout=5 vps-godaddy 'echo ok'
```

…returns `ok` non-interactively. After that, VS Code Remote-SSH "just works" (see [runbook 03](03-connect-from-vs-code.md)).

## Notes and gotchas

- **"Connection refused" vs "Connection timed out"** are different. *Refused* = something replied with TCP RST (host up, port closed). *Timed out* = no reply at all (host down or firewall dropping silently). Diagnose accordingly.
- **`ssh-add -l` returning "The agent has no identities" is normal at fresh terminal startup on macOS.** The agent loads keys lazily when something tries to use them, IF Keychain integration is on. So an empty `ssh-add -l` is NOT diagnostic by itself.
- **VS Code's Remote-SSH writes its own logs.** View → Output → choose "Remote-SSH" from the dropdown. The exact `ssh` command line VS Code invoked is in there, along with the exit code and any error message. Always check this before guessing.
- **The `workflow-debugger` agent** ([LEDGER-0002](../../LEDGER-0002-workflow-debugger-agent/)) is the right specialist to spawn for cryptic SSH or CI bugs. Its mindset section already cites the BatchMode/Keychain pattern as an example.

## Related

- [01-install-remote-ssh-extension.md](01-install-remote-ssh-extension.md), [02-configure-ssh-alias.md](02-configure-ssh-alias.md), [03-connect-from-vs-code.md](03-connect-from-vs-code.md)
- Playbook: [`playbooks/install.sh`](../playbooks/install.sh) `test` action runs a subset of these diagnostics non-interactively.
