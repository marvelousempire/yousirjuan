#!/usr/bin/env bash
# create-claude-user-mac.sh — macOS local user + authorized_keys + Remote Login.
# Run on the Mac as an admin: bash create-claude-user-mac.sh

set -euo pipefail

USER_NAME="${USER_NAME:-claude}"
PUBKEY_FILE="${PUBKEY_FILE:-$HOME/.ssh/id_ed25519.pub}"
GIVE_ADMIN="${GIVE_ADMIN:-0}"
NOPASSWD_SUDO="${NOPASSWD_SUDO:-0}"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }

[[ "$(uname -s)" == Darwin ]] || die "macOS only"
[[ -f "$PUBKEY_FILE" ]] || die "Missing pubkey: $PUBKEY_FILE"
PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")

if ! id "$USER_NAME" &>/dev/null; then
  PW=$(openssl rand -base64 24)
  echo "Creating user $USER_NAME (password stored only in macOS Keychain via sysadminctl)…"
  if [[ "$GIVE_ADMIN" == 1 ]]; then
    sudo sysadminctl -addUser "$USER_NAME" -fullName "Claude Agent" -shell /bin/zsh -password "$PW" -admin
  else
    sudo sysadminctl -addUser "$USER_NAME" -fullName "Claude Agent" -shell /bin/zsh -password "$PW"
  fi
fi

H="/Users/${USER_NAME}"
sudo mkdir -p "$H/.ssh"
if ! sudo grep -qF "$PUBKEY" "$H/.ssh/authorized_keys" 2>/dev/null; then
  echo "$PUBKEY" | sudo tee -a "$H/.ssh/authorized_keys" >/dev/null
fi
sudo chmod 700 "$H/.ssh"
sudo chmod 600 "$H/.ssh/authorized_keys"
sudo chown -R "${USER_NAME}:staff" "$H/.ssh"

if [[ "$NOPASSWD_SUDO" == 1 ]]; then
  echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${USER_NAME}" >/dev/null
  sudo chmod 440 "/etc/sudoers.d/${USER_NAME}"
fi

# Remote Login (SSH)
if ! sudo systemsetup -getremotelogin 2>/dev/null | grep -q On; then
  echo "Enabling Remote Login (SSH)…"
  sudo systemsetup -setremotelogin on
fi

echo "OK: macOS user $USER_NAME"
echo "Note: passphrase keys need: ssh-add --apple-use-keychain ~/.ssh/id_ed25519"
echo "Test: ssh ${USER_NAME}@127.0.0.1"
