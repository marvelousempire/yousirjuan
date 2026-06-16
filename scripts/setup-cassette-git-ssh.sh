#!/usr/bin/env bash
# Cassette-standard git SSH — token-free, no OAuth/SSO for git transport.
#
# Web SSO (Nephew OIDC) = browser doors only (Gitea UI, Pockit, GitLab web).
# Git push/pull = SSH keys in macOS keychain — same pattern as every cassette deploy.
#
# Usage:
#   bash scripts/setup-cassette-git-ssh.sh          # install + test
#   bash scripts/setup-cassette-git-ssh.sh --check  # test only
#
# Idempotent: appends marked blocks to ~/.ssh/config; never removes operator edits.

set -euo pipefail

MODE="${1:-install}"
SSH_CONFIG="${HOME}/.ssh/config"
MARK_BEGIN="# >>> cassette-git-ssh (yousirjuan) >>>"
MARK_END="# <<< cassette-git-ssh <<<"

GITHUB_KEY="${GITHUB_SSH_KEY:-${HOME}/.ssh/id_ed25519_github_marvelousempire}"
GITEA_KEY="${GITEA_SSH_KEY:-${HOME}/.ssh/id_ed25519_gitlab_FIVEMAC}"
GITEA_HOST_ALIAS="${GITEA_HOST:-gitea-dgx}"

ensure_key() {
  if [[ -f "$GITHUB_KEY" ]]; then
    return 0
  fi
  echo "→ generating GitHub key: $GITHUB_KEY"
  ssh-keygen -t ed25519 -C "fivemac-github-marvelousempire-$(date +%Y%m%d)" -f "$GITHUB_KEY" -N ""
}

load_keys() {
  for k in "$GITHUB_KEY" "$GITEA_KEY" "${HOME}/.ssh/id_ed25519"; do
    [[ -f "$k" ]] || continue
    ssh-add --apple-use-keychain "$k" 2>/dev/null || ssh-add "$k" 2>/dev/null || true
  done
}

install_ssh_blocks() {
  mkdir -p "${HOME}/.ssh"
  chmod 700 "${HOME}/.ssh"
  touch "$SSH_CONFIG"
  chmod 600 "$SSH_CONFIG"

  if grep -qF "$MARK_BEGIN" "$SSH_CONFIG" 2>/dev/null; then
    echo "ℹ cassette-git-ssh block already in $SSH_CONFIG"
    return 0
  fi

  ensure_key

  cat >>"$SSH_CONFIG" <<EOF

$MARK_BEGIN
# GitHub mirror lane — SSH only (never OAuth/credential-helper for git)
Host github.com
    HostName github.com
    User git
    IdentityFile $GITHUB_KEY
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UseKeychain yes
    AddKeysToAgent yes

# Gitea forge master — WireGuard (Plan 0180: LAN :2424 closed)
Host $GITEA_HOST_ALIAS dgx-git dgx-gitea
    HostName 10.1.0.5
    User git
    Port 2424
    IdentityFile $GITEA_KEY
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UseKeychain yes
    AddKeysToAgent yes

# Gitea public git door (VPS edge over WG)
Host clinic-gitlab git.jailynmarvin.com
    HostName clinic.jailynmarvin.com
    User git
    Port 2424
    IdentityFile $GITEA_KEY
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
    UseKeychain yes
    AddKeysToAgent yes
$MARK_END
EOF
  echo "✓ appended cassette-git-ssh block to $SSH_CONFIG"
}

test_host() {
  local label="$1" host="$2"
  if out="$(ssh -o BatchMode=yes -o ConnectTimeout=8 -T "$host" 2>&1)"; then
    echo "  ✓ $label — $out"
    return 0
  fi
  if [[ "$out" == *"successfully authenticated"* ]] || [[ "$out" == *"Hi "* ]]; then
    echo "  ✓ $label — authenticated"
    return 0
  fi
  echo "  ✗ $label — $out"
  return 1
}

run_checks() {
  local ok=0
  echo "=== Cassette git SSH check ==="
  test_host "Gitea forge ($GITEA_HOST_ALIAS)" "git@${GITEA_HOST_ALIAS}" || ok=1
  test_host "GitHub (origin)" "git@github.com" || ok=1
  if [[ $ok -ne 0 ]]; then
    echo ""
    echo "GitHub fix (boss move — one time):"
    echo "  1. Open https://github.com/settings/keys → New SSH key"
    echo "  2. Paste this public key:"
    echo ""
    cat "${GITHUB_KEY}.pub" 2>/dev/null || echo "    (missing ${GITHUB_KEY}.pub — re-run without --check)"
    echo ""
    echo "  3. If marvelousempire uses SAML SSO: click **Configure SSO** beside the key → Authorize"
    echo "     (SSO authorizes the KEY for the org — git does not use browser OIDC login.)"
    echo ""
    echo "Gitea master still works without GitHub: git push gitea main  (or make forge-push)"
    return 1
  fi
  echo "✓ cassette git SSH ready"
  return 0
}

case "$MODE" in
  --check|check)
    run_checks
    ;;
  install|"")
    install_ssh_blocks
    load_keys
    run_checks || true
    ;;
  *)
    echo "Usage: $0 [install|--check]"
    exit 2
    ;;
esac
