#!/usr/bin/env bash
# create-claude-user.sh — idempotent Linux / OpenWrt user + SSH key + optional sudo.
# Strictly AI-free. Run as root on the target host (or: ssh admin@host 'sudo bash -s' < this).
#
# Env:
#   USER_NAME=claude          (default)
#   PUBKEY=                   (required unless PUBKEY_FILE set)
#   PUBKEY_FILE=              (read one line from file)
#   NOPASSWD_SUDO=1|0         (default 1 on Debian/Ubuntu, 0 on OpenWrt)
#   PLATFORM=auto|linux|openwrt
#   PASSWORD=                 (optional: if set, sets the login password via chpasswd on Linux)
#   SSH_ALLOW=1               (default 1: append to sshd AllowUsers if the file exists)

set -euo pipefail

USER_NAME="${USER_NAME:-claude}"
NOPASSWD_SUDO="${NOPASSWD_SUDO:-}"
PLATFORM="${PLATFORM:-auto}"
PASSWORD="${PASSWORD:-}"
SSH_ALLOW="${SSH_ALLOW:-1}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }

[[ $EUID -eq 0 ]] || die "Run as root: sudo bash $0"

if [[ -z "${PUBKEY:-}" && -n "${PUBKEY_FILE:-}" && -f "$PUBKEY_FILE" ]]; then
  PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")
fi
[[ -n "${PUBKEY:-}" ]] || die "Set PUBKEY or PUBKEY_FILE to your ssh-ed25519 public key (one line)."

# Normalize pubkey (collapse accidental newlines from paste)
PUBKEY="${PUBKEY//$'\n'/ }"
PUBKEY="${PUBKEY//$'\r'/}"

if [[ "$PLATFORM" == auto ]]; then
  if [[ -f /etc/openwrt_release ]] || grep -qF OpenWrt /etc/os-release 2>/dev/null; then
    PLATFORM=openwrt
  else
    PLATFORM=linux
  fi
fi

if [[ -z "$NOPASSWD_SUDO" ]]; then
  [[ "$PLATFORM" == openwrt ]] && NOPASSWD_SUDO=0 || NOPASSWD_SUDO=1
fi

step() { printf '→ %s\n' "$*"; }

# --- create user ---
if [[ "$PLATFORM" == linux ]] && command -v useradd >/dev/null 2>&1; then
  step "Linux useradd path ($USER_NAME)"
  id "$USER_NAME" >/dev/null 2>&1 || useradd -m -s /bin/bash "$USER_NAME"
  getent group sudo  >/dev/null 2>&1 && usermod -aG sudo  "$USER_NAME" || true
  getent group wheel >/dev/null 2>&1 && usermod -aG wheel "$USER_NAME" || true
  # UGOS Pro: SSH often requires the admin group (else "This account is currently not available")
  if getent group admin >/dev/null 2>&1; then
    step "UGOS admin group: add $USER_NAME for SSH"
    usermod -aG admin "$USER_NAME" || true
  fi
  usermod -U "$USER_NAME" 2>/dev/null || true
  usermod -s /bin/bash "$USER_NAME" 2>/dev/null || true

  # Set password if provided (Linux)
  if [[ -n "$PASSWORD" ]]; then
    step "Setting password for $USER_NAME"
    echo "$USER_NAME:$PASSWORD" | chpasswd
  fi
else
  step "OpenWrt / manual passwd path ($USER_NAME)"
  if ! id "$USER_NAME" >/dev/null 2>&1; then
    if command -v useradd >/dev/null 2>&1; then
      useradd -m -s /bin/ash "$USER_NAME" 2>/dev/null || useradd -m "$USER_NAME"
    else
      grep -q "^${USER_NAME}:" /etc/passwd || echo "${USER_NAME}:x:1000:1000:Claude:/home/${USER_NAME}:/bin/ash" >>/etc/passwd
      grep -q "^${USER_NAME}:" /etc/group  || echo "${USER_NAME}:x:1000:" >>/etc/group
    fi
  fi
  mkdir -p "/home/${USER_NAME}"

  # Set password if provided (basic systems)
  if [[ -n "$PASSWORD" && -x /usr/sbin/chpasswd ]]; then
    echo "$USER_NAME:$PASSWORD" | chpasswd
  fi
fi

# --- passwordless sudo (optional) ---
if [[ "$NOPASSWD_SUDO" == 1 && -d /etc/sudoers.d ]]; then
  step "sudoers.d NOPASSWD for $USER_NAME"
  printf '%s ALL=(ALL) NOPASSWD:ALL\n' "$USER_NAME" >"/etc/sudoers.d/${USER_NAME}"
  chmod 440 "/etc/sudoers.d/${USER_NAME}"
fi

# --- SSH key ---
H="/home/${USER_NAME}"
mkdir -p "$H/.ssh"
touch "$H/.ssh/authorized_keys"
grep -qF "$PUBKEY" "$H/.ssh/authorized_keys" 2>/dev/null || echo "$PUBKEY" >>"$H/.ssh/authorized_keys"
chmod 700 "$H/.ssh"
chmod 600 "$H/.ssh/authorized_keys"
chown -R "${USER_NAME}:${USER_NAME}" "$H" 2>/dev/null || chown -R "$USER_NAME" "$H" 2>/dev/null || true
# OpenWrt dropbear rejects root-owned authorized_keys (common GL.iNet mistake)
chown -R "${USER_NAME}:${USER_NAME}" "$H/.ssh" 2>/dev/null || true

# OpenWrt dropbear: ensure shell user can log in (no extra config if PermitRootLogin only issue)
if [[ "$PLATFORM" == openwrt ]] && [[ -f /etc/config/dropbear ]]; then
  if uci get dropbear.@dropbear[0].PasswordAuth 2>/dev/null | grep -q 1; then
    step "dropbear: consider PasswordAuth off after key login works"
  fi
fi

# sshd AllowUsers — append user if a drop-in lists only the legacy admin user (ACL)
if [[ "$SSH_ALLOW" == 1 ]]; then
  ALLOW_FILE=/etc/ssh/sshd_config.d/60-allowusers.conf
  if [[ -f "$ALLOW_FILE" ]] && grep -q '^AllowUsers ' "$ALLOW_FILE"; then
    if ! grep -qw "$USER_NAME" "$ALLOW_FILE"; then
      step "sshd AllowUsers: append $USER_NAME in $ALLOW_FILE (ACL)"
      sed -i "s/^AllowUsers /AllowUsers $USER_NAME /" "$ALLOW_FILE" || true
      if ! grep -qw "$USER_NAME" "$ALLOW_FILE"; then
        echo "AllowUsers $USER_NAME" >>"$ALLOW_FILE"
      fi
      systemctl reload ssh 2>/dev/null || service ssh reload 2>/dev/null || true
    fi
  fi
fi

printf 'OK: user %s; key installed; groups: %s; platform=%s; nopasswd_sudo=%s\n' \
  "$USER_NAME" "$(id -nG "$USER_NAME" 2>/dev/null || echo unknown)" "$PLATFORM" "$NOPASSWD_SUDO"
