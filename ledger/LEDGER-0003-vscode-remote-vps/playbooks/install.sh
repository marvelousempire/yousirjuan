#!/usr/bin/env bash
#
# install.sh — set up VS Code Remote-SSH access to vps-godaddy on a fresh Mac.
#
# Actions:
#   install    — install Remote-SSH extension, append SSH alias (after confirm),
#                verify connectivity. Idempotent: re-running is a no-op.
#   uninstall  — remove the SSH alias (after confirm), uninstall the extension.
#   status     — print state of every piece, no mutations.
#   test       — run the 90-second triage from runbook 04 non-interactively.
#   help       — print usage.
#
# Variables (override via env):
#   VPS_HOST     — VPS public IP (default: 72.167.151.251)
#   VPS_PORT     — SSH port on the VPS (default: 2222)
#   VPS_USER     — SSH user on the VPS (default: abrownsanta)
#   SSH_KEY      — local private key (default: $HOME/.ssh/id_ed25519)
#   SSH_ALIAS    — alias name in ~/.ssh/config (default: vps-godaddy)
#
# All output also tee'd to ~/yousirjuan-ledger.log.

set -euo pipefail

VPS_HOST="${VPS_HOST:-72.167.151.251}"
VPS_PORT="${VPS_PORT:-2222}"
VPS_USER="${VPS_USER:-abrownsanta}"
SSH_KEY="${SSH_KEY:-$HOME/.ssh/id_ed25519}"
SSH_ALIAS="${SSH_ALIAS:-vps-godaddy}"
SSH_CONFIG="$HOME/.ssh/config"
LEDGER_LOG="$HOME/yousirjuan-ledger.log"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNIPPET="$SCRIPT_DIR/../artifacts/ssh-config-snippet.txt"

mkdir -p "$(dirname "$LEDGER_LOG")"
exec > >(tee -a "$LEDGER_LOG") 2>&1

# ───── colors + helpers (canonical yousirjuan set) ─────
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ───── safe SSH-config mutation (idempotent + per-edit consent) ─────
# Default behavior is to PROMPT before writing. Set ASSUME_YES=1 to skip.
confirm() {
  local prompt="$1"
  if [[ "${ASSUME_YES:-0}" == "1" ]]; then
    note "ASSUME_YES=1; proceeding: $prompt"
    return 0
  fi
  if [[ ! -t 0 ]]; then
    warn "Non-interactive context detected for prompt: $prompt"
    warn "Set ASSUME_YES=1 to allow non-interactive consent. Skipping."
    return 1
  fi
  printf "${YELLOW}  ? %s [y/N] ${NC}" "$prompt" >&2
  local r; read -r r
  [[ "$r" =~ ^[Yy]$ ]]
}

# ───── individual checks ─────
action_help() {
  cat <<EOF
Usage: $0 <action>

Actions:
  install    Install Remote-SSH extension + append SSH alias + verify.
  uninstall  Remove the SSH alias + extension (with per-step confirmation).
  status     Print state of every piece, no mutations.
  test       Run the 90-second triage from runbook 04 non-interactively.
  help       Print this.

Variables (override via env):
  VPS_HOST=$VPS_HOST
  VPS_PORT=$VPS_PORT
  VPS_USER=$VPS_USER
  SSH_KEY=$SSH_KEY
  SSH_ALIAS=$SSH_ALIAS
  ASSUME_YES=0   (set to 1 to skip confirm prompts)

Logs: $LEDGER_LOG
EOF
}

check_code_cli() {
  if have code; then
    ok "\`code\` CLI on PATH: $(command -v code)"
    return 0
  else
    warn "\`code\` CLI not on PATH. Install via VS Code (⇧⌘P → Shell Command: Install 'code' command in PATH), or see LEDGER-0001 runbook 01."
    return 1
  fi
}

check_extension() {
  if ! have code; then
    warn "Cannot check VS Code extensions without \`code\` CLI"
    return 1
  fi
  if code --list-extensions 2>/dev/null | grep -q "ms-vscode-remote.remote-ssh"; then
    ok "Remote-SSH extension installed"
    return 0
  else
    warn "Remote-SSH extension NOT installed"
    return 1
  fi
}

check_key_exists() {
  if [[ -f "$SSH_KEY" ]]; then
    ok "SSH key exists at $SSH_KEY"
    return 0
  else
    warn "SSH key NOT found at $SSH_KEY (generate one with: ssh-keygen -t ed25519)"
    return 1
  fi
}

check_alias_in_config() {
  if [[ ! -f "$SSH_CONFIG" ]]; then
    warn "$SSH_CONFIG does not exist"
    return 1
  fi
  if grep -qE "^Host[[:space:]]+$SSH_ALIAS\\b" "$SSH_CONFIG"; then
    ok "$SSH_ALIAS alias present in $SSH_CONFIG"
    return 0
  else
    warn "$SSH_ALIAS alias NOT in $SSH_CONFIG"
    return 1
  fi
}

check_alias_resolves() {
  local h p u
  h=$(ssh -G "$SSH_ALIAS" 2>/dev/null | awk '$1=="hostname"{print $2}')
  p=$(ssh -G "$SSH_ALIAS" 2>/dev/null | awk '$1=="port"{print $2}')
  u=$(ssh -G "$SSH_ALIAS" 2>/dev/null | awk '$1=="user"{print $2}')
  if [[ "$h" == "$VPS_HOST" && "$p" == "$VPS_PORT" && "$u" == "$VPS_USER" ]]; then
    ok "$SSH_ALIAS resolves: $u@$h:$p"
    return 0
  else
    warn "$SSH_ALIAS resolves to: $u@$h:$p (expected $VPS_USER@$VPS_HOST:$VPS_PORT)"
    return 1
  fi
}

check_port_open() {
  if nc -z -G 5 "$VPS_HOST" "$VPS_PORT" 2>/dev/null; then
    ok "port $VPS_PORT open on $VPS_HOST"
    return 0
  else
    warn "port $VPS_PORT NOT reachable on $VPS_HOST (network / firewall / fail2ban)"
    return 1
  fi
}

check_ssh_works() {
  local result
  result=$(ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_ALIAS" 'echo ok' 2>&1 || true)
  if [[ "$result" == "ok" ]]; then
    ok "ssh $SSH_ALIAS 'echo ok' returned ok (non-interactive)"
    return 0
  else
    warn "ssh $SSH_ALIAS test returned: $result"
    note "(if this is BatchMode/Keychain related, an interactive ssh will succeed once you enter the passphrase. See runbook 04.)"
    return 1
  fi
}

# ───── actions ─────
action_status() {
  echo "── prerequisites ────────────────────────"
  check_code_cli || true
  check_key_exists || true
  echo "── VS Code extension ────────────────────"
  check_extension || true
  echo "── SSH config ───────────────────────────"
  check_alias_in_config || true
  check_alias_resolves || true
  echo "── network ──────────────────────────────"
  check_port_open || true
  echo "── SSH end-to-end ───────────────────────"
  check_ssh_works || true
}

action_test() {
  step "90-second triage (read-only)"
  echo "─ layer 1: ICMP ─"
  ping -c 1 -W 2000 "$VPS_HOST" 2>&1 | head -3
  echo "─ layer 2: TCP on $VPS_PORT ─"
  nc -z -G 5 -v "$VPS_HOST" "$VPS_PORT" 2>&1 | head -2
  echo "─ layer 2: TCP on 22 (does default port work?) ─"
  nc -z -G 5 -v "$VPS_HOST" 22 2>&1 | head -2
  echo "─ layer 3: SSH banner ─"
  echo "" | nc -G 5 "$VPS_HOST" "$VPS_PORT" 2>&1 | head -1
  echo "─ layer 4: alias resolution ─"
  ssh -G "$SSH_ALIAS" 2>&1 | grep -E "^(hostname|user|port|identityfile)"
  echo "─ layer 5: agent identities ─"
  ssh-add -l 2>&1 | head -3 || true
  echo "─ layer 6: SSH non-interactive ─"
  ssh -o ConnectTimeout=5 -o BatchMode=yes "$SSH_ALIAS" 'echo ok' 2>&1 | head -3 || true
  echo ""
  note "Compare output to patterns A–F in runbooks/04-troubleshoot-refused-connections.md."
}

action_install() {
  step "Installing Remote-SSH extension"
  if ! check_code_cli; then
    die "Install VS Code first, and put the \`code\` CLI on PATH"
  fi
  if check_extension; then
    note "skip"
  else
    code --install-extension ms-vscode-remote.remote-ssh 2>&1 | tail -2
    check_extension || die "extension install failed"
  fi

  step "Checking SSH key"
  check_key_exists || die "no key at $SSH_KEY; generate one and authorize server-side first"

  step "Updating $SSH_CONFIG"
  if check_alias_in_config; then
    note "$SSH_ALIAS already in $SSH_CONFIG; not modifying"
  else
    if [[ ! -f "$SNIPPET" ]]; then
      die "canonical snippet not found at $SNIPPET"
    fi
    note "Will append the following block to $SSH_CONFIG:"
    sed 's/^/    /' "$SNIPPET"
    if confirm "Append this Host $SSH_ALIAS block to $SSH_CONFIG?"; then
      mkdir -p "$(dirname "$SSH_CONFIG")"
      touch "$SSH_CONFIG"
      cp "$SSH_CONFIG" "${SSH_CONFIG}.before-vps-godaddy-$(date +%Y%m%d-%H%M%S).bak"
      cat "$SNIPPET" >> "$SSH_CONFIG"
      ok "appended; backup saved alongside"
    else
      warn "user declined to append; aborting"
      return 1
    fi
  fi

  step "Verifying alias"
  check_alias_resolves || die "alias resolution failed; check $SSH_CONFIG syntax"

  step "Verifying port reachable"
  check_port_open || warn "port unreachable; see runbook 04"

  step "Verifying SSH end-to-end (non-interactive)"
  check_ssh_works || warn "SSH non-interactive failed; almost always Keychain/BatchMode — open VS Code or a fresh terminal and try interactively"

  echo ""
  ok "Setup complete."
  note "Open a remote VS Code window with:"
  echo "    code --remote ssh-remote+$SSH_ALIAS /home/$VPS_USER"
}

action_uninstall() {
  step "Removing $SSH_ALIAS alias from $SSH_CONFIG"
  if check_alias_in_config; then
    if confirm "Remove the Host $SSH_ALIAS stanza from $SSH_CONFIG?"; then
      cp "$SSH_CONFIG" "${SSH_CONFIG}.before-uninstall-$(date +%Y%m%d-%H%M%S).bak"
      python3 -c "
import re, sys
p = '$SSH_CONFIG'
s = open(p).read()
s = re.sub(r'\n(# yousirjuan VPS.*?\n|# Canonical Host stanza.*?\n)?Host $SSH_ALIAS\n(    .+\n)+', '\n', s)
open(p,'w').write(s)
"
      ok "alias removed; backup saved alongside"
    else
      warn "user declined; leaving alias in place"
    fi
  else
    note "alias not present; nothing to remove"
  fi

  step "Uninstalling Remote-SSH extension"
  if check_extension; then
    if confirm "Uninstall ms-vscode-remote.remote-ssh and dependents?"; then
      code --uninstall-extension ms-vscode-remote.remote-ssh 2>&1 | tail -1 || true
      code --uninstall-extension ms-vscode-remote.remote-ssh-edit 2>&1 | tail -1 || true
      code --uninstall-extension ms-vscode.remote-explorer 2>&1 | tail -1 || true
      ok "uninstalled"
    fi
  fi

  note "VS Code Server on the remote (\$HOME/.vscode-server on the VPS) is left in place."
  note "To clean it: ssh $SSH_ALIAS 'rm -rf ~/.vscode-server'"
  ok "uninstall complete"
}

# ───── dispatcher ─────
case "${1:-help}" in
  install)   action_install ;;
  uninstall) action_uninstall ;;
  status)    action_status ;;
  test)      action_test ;;
  help|-h|--help) action_help ;;
  *)         echo "Unknown action: $1" >&2; action_help; exit 1 ;;
esac
