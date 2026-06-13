#!/usr/bin/env bash
# set-claude-password.sh — Generate (if needed) and apply the default CLAUDE_PASSWORD to targets.
#
# Sources operator-hosts.env for CLAUDE_PASSWORD.
# If not set, generates a strong one, saves it to the env file (gitignored), and applies.
#
# Usage:
#   bash playbooks/set-claude-password.sh dgx vps
#   bash playbooks/set-claude-password.sh --generate-only   # just ensure password exists in env
#
# This is the canonical way to (re)set the password for claude + Members across the fleet.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
ARTIFACTS="$(cd "$ROOT/../artifacts" && pwd)"

# Unified secret loading (tower-first).
# tower.env must be protected (chmod 600, not in any directory AI tools are allowed to scan).
# AI must never read the real tower.env.
TOWER_ENV_FILE="${TOWER_ENV:-${HOME}/.config/tower/tower.env}"
if [[ -f "$TOWER_ENV_FILE" ]]; then
  ENV_FILE="$TOWER_ENV_FILE"
elif [[ -n "${OPERATOR_HOSTS_ENV:-}" && -f "$OPERATOR_HOSTS_ENV" ]]; then
  ENV_FILE="$OPERATOR_HOSTS_ENV"
else
  ENV_FILE="$ARTIFACTS/operator-hosts.env"
fi

if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

GENERATE_ONLY=false
TARGETS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --generate-only) GENERATE_ONLY=true; shift ;;
    *) TARGETS+=("$1"); shift ;;
  esac
done

# Ensure CLAUDE_PASSWORD exists
if [[ -z "${CLAUDE_PASSWORD:-}" ]]; then
  echo "No CLAUDE_PASSWORD in env — generating strong default..."
  NEW_PW=$(openssl rand -base64 24 | tr -d '\n=+/')
  echo "" >> "$ENV_FILE"
  echo "# Auto-generated CLAUDE_PASSWORD on $(date)" >> "$ENV_FILE"
  echo "CLAUDE_PASSWORD=$NEW_PW" >> "$ENV_FILE"
  export CLAUDE_PASSWORD="$NEW_PW"
  echo "Saved to $ENV_FILE (gitignored). Length: ${#NEW_PW}"
else
  echo "Using existing CLAUDE_PASSWORD from env (length ${#CLAUDE_PASSWORD})"
fi

if $GENERATE_ONLY; then
  echo "Password ensured. Exiting (--generate-only)."
  exit 0
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo "No targets specified. Defaulting to dgx vps."
  TARGETS=(dgx vps)
fi

for t in "${TARGETS[@]}"; do
  case "$t" in
    dgx|nephew-spark)
      echo "→ Applying to DGX ($t)..."
      ssh nephew-spark "echo 'claude:$CLAUDE_PASSWORD' | sudo chpasswd" && echo "  OK on DGX"
      ;;
    vps|clinic-vps)
      echo "→ Applying to VPS..."
      # Adjust host if needed
      ssh -p "${VPS_SSH_PORT:-2222}" "${VPS_SSH:-abrownsanta@251.151.167.72.host.secureserver.net}" \
        "echo 'claude:$CLAUDE_PASSWORD' | sudo chpasswd" && echo "  OK on VPS"
      ;;
    *)
      echo "→ For $t: run manually on the box: echo 'claude:$CLAUDE_PASSWORD' | sudo chpasswd"
      ;;
  esac
done

echo "Done. Verify with: ssh <target> 'sudo passwd -S claude'"
