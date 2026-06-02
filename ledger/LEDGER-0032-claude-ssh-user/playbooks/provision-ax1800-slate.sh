#!/usr/bin/env bash
# provision-ax1800-slate.sh — GL-AX1800 (Slate) @ 192.168.9.1, login user root.
#
# Usage:
#   read -s SLATE_PASSWORD; echo
#   SLATE_PASSWORD="$SLATE_PASSWORD" bash provision-ax1800-slate.sh
#
# Web UI: https://192.168.9.1 — root (not Flint admin @ 192.168.8.1).

set -euo pipefail

ARTIFACTS="$(cd "$(dirname "$0")/../artifacts" && pwd)"
ENV_FILE="${OPERATOR_HOSTS_ENV:-$ARTIFACTS/operator-hosts.env}"
[[ -f "$ENV_FILE" ]] && source "$ENV_FILE"

HOST="${SLATE_HOST:-${UPSTREAM_GW:-192.168.9.1}}"
PASS="${SLATE_PASSWORD:-}"
PUBKEY_FILE="${PUBKEY_FILE:-$HOME/.ssh/id_ed25519.pub}"
SSH_USERS="${SLATE_SSH_USERS:-root,admin}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }
[[ -n "$PASS" ]] || die "Set SLATE_PASSWORD"
[[ -f "$PUBKEY_FILE" ]] || die "Missing $PUBKEY_FILE"
command -v sshpass >/dev/null || die "Install sshpass: brew install sshpass"

PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")
PF=$(mktemp); chmod 600 "$PF"; printf '%s' "$PASS" >"$PF"

SSH_USER=""
IFS=',' read -r -a _users <<<"$SSH_USERS"
for u in "${_users[@]}"; do
  u="${u// /}"
  [[ -n "$u" ]] || continue
  printf '→ Trying SSH %s@%s …\n' "$u" "$HOST"
  if sshpass -f "$PF" ssh -o StrictHostKeyChecking=accept-new -o ConnectTimeout=12 \
    -o PreferredAuthentications=password -o PubkeyAuthentication=no \
    "${u}@${HOST}" 'echo ssh-ok' 2>/dev/null | grep -q ssh-ok; then
    SSH_USER="$u"
    break
  fi
done

if [[ -z "$SSH_USER" ]]; then
  rm -f "$PF"
  die "SSH login failed for users: ${SSH_USERS}@${HOST}

  1. Browser: https://${HOST} as root (not 192.168.8.1 Flint).
  2. System → Security → SSH → Enable SSH → Apply.
  3. Test: ssh root@${HOST}"
fi

echo "→ Logged in as ${SSH_USER}@${HOST}; installing claude…"
sshpass -f "$PF" ssh -o StrictHostKeyChecking=accept-new \
  -o PreferredAuthentications=password -o PubkeyAuthentication=no "${SSH_USER}@${HOST}" \
  "PUBKEY='$PUBKEY'; id claude >/dev/null 2>&1 || { echo 'claude:x:1000:1000:Claude:/home/claude:/bin/ash' >> /etc/passwd; echo 'claude:x:1000:' >> /etc/group; }; \
   mkdir -p /home/claude/.ssh; grep -qF \"\$PUBKEY\" /home/claude/.ssh/authorized_keys 2>/dev/null || echo \"\$PUBKEY\" >> /home/claude/.ssh/authorized_keys; \
   chown -R claude:claude /home/claude; chmod 700 /home/claude/.ssh; chmod 600 /home/claude/.ssh/authorized_keys; echo OK-claude"

rm -f "$PF"
unset PASS

eval "$(/usr/bin/ssh-agent -s)" >/dev/null 2>&1
ssh-add --apple-use-keychain "$PUBKEY_FILE" 2>/dev/null || true
ssh -o BatchMode=yes -i "$PUBKEY_FILE" "claude@${HOST}" 'id; echo ax1800-claude-ok'
