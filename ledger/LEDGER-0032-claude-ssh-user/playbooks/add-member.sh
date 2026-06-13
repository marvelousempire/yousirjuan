#!/usr/bin/env bash
# add-member.sh — Add a human Member (or the claude AI user) to the fleet with full ACL.
#
# Usage:
#   bash add-member.sh avery dgx vps
#   bash add-member.sh --user claude --targets dgx
#   bash add-member.sh --list   # show configured members from env
#
# It sources operator-hosts.env for CLAUDE_PASSWORD (used as default if no per-member pw),
# PUBKEY_FILE, and bootstrap info.
#
# For a new Member, you must provide their pubkey (or pre-install it).
# Password: falls back to CLAUDE_PASSWORD if set.
#
# ACL applied: sudo (NOPASSWD optional), sshd AllowUsers, groups, macOS access_ssh, etc.
# via the create-*.sh scripts.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS="$(cd "$ROOT/../artifacts" && pwd)"

# Unified secret loading (tower-first for AI protection).
# Real secrets live only in protected tower.env (600 perms, outside y ousirjuan / ~/.claude etc.).
# AI agents are forbidden from reading the live tower.env or real operator-hosts.env.
TOWER_ENV_FILE="${TOWER_ENV:-${HOME}/.config/tower/tower.env}"
if [[ -f "$TOWER_ENV_FILE" ]]; then
  ENV_FILE="$TOWER_ENV_FILE"
elif [[ -n "${OPERATOR_HOSTS_ENV:-}" && -f "$OPERATOR_HOSTS_ENV" ]]; then
  ENV_FILE="$OPERATOR_HOSTS_ENV"
else
  ENV_FILE="$ARTIFACTS/operator-hosts.env"
fi

CREATE_LINUX="$ROOT/create-claude-user.sh"
CREATE_MAC="$ROOT/create-claude-user-mac.sh"
MAC_REMOTE="$ROOT/provision-macos-remote.sh"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }

if [[ -f "$ENV_FILE" ]]; then
  # shellcheck source=/dev/null
  source "$ENV_FILE"
else
  printf '! No %s — using defaults.\n' "$ENV_FILE" >&2
fi

: "${PUBKEY_FILE:=${HOME}/.ssh/id_ed25519.pub}"
: "${CLAUDE_PASSWORD:=}"

USER_NAME="${USER_NAME:-}"
TARGETS=()
LIST_ONLY=false
NOPASSWD_SUDO=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --user|-u)
      USER_NAME="$2"; shift 2 ;;
    --targets|-t)
      shift
      while [[ $# -gt 0 && ! "$1" =~ ^- ]]; do
        TARGETS+=("$1"); shift
      done ;;
    --list)
      LIST_ONLY=true; shift ;;
    --no-nopasswd)
      NOPASSWD_SUDO=0; shift ;;
    *)
      if [[ -z "$USER_NAME" ]]; then
        USER_NAME="$1"
      else
        TARGETS+=("$1")
      fi
      shift ;;
  esac
done

if $LIST_ONLY; then
  echo "Configured members / users (from env + defaults):"
  echo "  claude (AI automation, shared)"
  # Future: parse MEMBER_* or MEMBERS= list
  grep -E '^(MEMBER_|MEMBERS=|.+_NAME=)' "$ENV_FILE" 2>/dev/null || true
  exit 0
fi

[[ -n "$USER_NAME" ]] || die "Usage: $0 <username> [dgx vps mac ...]  or --user <name> --targets ..."
[[ -f "$PUBKEY_FILE" ]] || die "Missing pubkey: $PUBKEY_FILE"

# Default password for this user (prefer CLAUDE_PASSWORD, allow override via env like AVERY_PASSWORD)
PW_VAR_NAME="$(echo "${USER_NAME^^}_PASSWORD" | tr - _)"
PASSWORD="${!PW_VAR_NAME:-$CLAUDE_PASSWORD}"

PUBKEY=$(tr -d '\n\r' <"$PUBKEY_FILE")

printf '\n=== Adding Member: %s ===\n' "$USER_NAME"
if [[ -n "$PASSWORD" ]]; then
  printf 'Password: will be set from %s (or CLAUDE_PASSWORD)\n' "${PW_VAR_NAME:-CLAUDE_PASSWORD}"
else
  printf 'No password provided (key-only + ACL)\n'
fi

# If no explicit targets, default to common Linux fleet for this user
if [[ ${#TARGETS[@]} -eq 0 ]]; then
  TARGETS=(dgx vps)
  printf 'No targets specified — defaulting to: %s\n' "${TARGETS[*]}"
fi

for t in "${TARGETS[@]}"; do
  case "$t" in
    dgx|dgx-spark|nephew-spark|vps|clinic-vps)
      # Linux path
      host_var="DGX_SSH"
      [[ "$t" == "vps" || "$t" == "clinic-vps" ]] && host_var="VPS_SSH"
      host="${!host_var:-}"
      if [[ -z "$host" ]]; then
        printf ' ! Skipping %s (no %s in env)\n' "$t" "$host_var"
        continue
      fi
      printf '\n→ %s (%s)\n' "$t" "$host"
      ssh -o BatchMode=yes -o ConnectTimeout=12 "$host" \
        "sudo env USER_NAME='$USER_NAME' PUBKEY='$PUBKEY' PASSWORD='${PASSWORD}' NOPASSWD_SUDO=$NOPASSWD_SUDO PLATFORM=linux bash -s" <"$CREATE_LINUX"
      ;;
    mac|bigmac|twomac|onemac|macs)
      printf '\n→ mac target %s\n' "$t"
      # Smarter Mac handling: look for per-mac bootstrap in env (e.g. MAC_BIGMAC_BOOTSTRAP)
      mac_label=$(echo "$t" | tr '[:upper:]' '[:lower:]')
      bootstrap_var="MAC_${mac_label^^}_BOOTSTRAP"
      bootstrap="${!bootstrap_var:-}"
      if [[ -n "$bootstrap" ]]; then
        printf '  Using bootstrap %s for remote provision...\n' "$bootstrap"
        bash "$MAC_REMOTE" "$mac_label" "$bootstrap" || true
      else
        echo "  No ${bootstrap_var} in env."
        echo "  Run directly on the target Mac: USER_NAME=$USER_NAME PASSWORD='$PASSWORD' bash create-claude-user-mac.sh"
        echo "  Or set MAC_XXX_BOOTSTRAP in operator-hosts.env and re-run."
      fi
      ;;
    *)
      printf ' ! Unknown target %s — skipping (extend the script or call create-*.sh directly)\n' "$t"
      ;;
  esac
done

printf '\nDone for %s. Verify with: ssh %s@target "whoami && sudo -n true && id"\n' "$USER_NAME" "$USER_NAME"
