#!/usr/bin/env bash
# LEDGER-0025 — install-credential.sh
#
# Idempotent installer for the GitHub fine-grained PAT used by
# LEDGER-0024's sync-and-drift.sh. Lays down /etc/yousirjuan-sync/credentials
# with mode 0600 owned by root, containing one line:
#
#   GITHUB_TOKEN=ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
#
# Usage (interactive — recommended; token never appears in shell history):
#   sudo bash install-credential.sh
#   <paste token at prompt + enter>
#
# Usage (--token flag, only for scripted contexts where shell history is OK):
#   sudo bash install-credential.sh --token ghp_xxxxxxxxxxxxxxx
#
# Usage (--from-stdin, for piped install from CI / Vault):
#   echo "ghp_xxxxx" | sudo bash install-credential.sh --from-stdin
#
# Re-running with a new token rotates: the file is replaced atomically.
# After install, manually run sync-and-drift.sh OR wait for the next
# 5-minute timer tick. Every bare repo will have its origin URL re-pointed
# to the new credentialled URL automatically by `git remote set-url`.

set -euo pipefail

CRED_DIR="${CRED_DIR:-/etc/yousirjuan-sync}"
CRED_FILE="${CRED_DIR}/credentials"

step()  { printf "▶ %s\n" "$*"; }
ok()    { printf "✓ %s\n" "$*"; }
warn()  { printf "⚠ %s\n" "$*" >&2; }
die()   { printf "✗ %s\n" "$*" >&2; exit 1; }
have()  { command -v "$1" >/dev/null 2>&1; }

# ──────────────────────────────────────────────────────────────────────
# Parse args
# ──────────────────────────────────────────────────────────────────────
MODE="interactive"
TOKEN_ARG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --token)
      MODE="flag"; TOKEN_ARG="${2:-}"; shift 2 ;;
    --from-stdin)
      MODE="stdin"; shift ;;
    -h|--help)
      sed -n '2,30p' "$0"; exit 0 ;;
    *)
      die "unknown arg: $1 (try -h)" ;;
  esac
done

# ──────────────────────────────────────────────────────────────────────
# Must be root
# ──────────────────────────────────────────────────────────────────────
if [ "$(id -u)" -ne 0 ]; then
  die "must run as root (sudo bash $0 ...)"
fi

# ──────────────────────────────────────────────────────────────────────
# Read the token from the chosen source
# ──────────────────────────────────────────────────────────────────────
TOKEN=""
case "$MODE" in
  interactive)
    printf "Paste GitHub fine-grained PAT (input hidden): " >&2
    read -rs TOKEN
    printf "\n" >&2
    ;;
  flag)
    TOKEN="$TOKEN_ARG"
    ;;
  stdin)
    TOKEN="$(cat | tr -d '\n\r ')"
    ;;
esac

[ -n "$TOKEN" ] || die "no token provided"
# Loose sanity — fine-grained PATs are 'github_pat_...', classic are 'ghp_...'
if ! printf "%s" "$TOKEN" | grep -qE '^(ghp_|github_pat_)[A-Za-z0-9_]{20,}$'; then
  warn "token doesn't look like a GitHub PAT (expected ghp_… or github_pat_…) — proceeding anyway"
fi

# ──────────────────────────────────────────────────────────────────────
# Lay down the file
# ──────────────────────────────────────────────────────────────────────
step "creating $CRED_DIR (if missing)"
install -d -m 0700 -o root -g root "$CRED_DIR"

step "writing $CRED_FILE (atomic)"
tmp="$(mktemp "${CRED_FILE}.XXXXXX")"
{
  printf "# LEDGER-0025 — GitHub PAT for sync-and-drift.sh\n"
  printf "# Permissions: contents:read + metadata:read on marvelousempire/*\n"
  printf "# Rotation: GitHub fine-grained PATs cap at 366 days.\n"
  printf "GITHUB_TOKEN=%s\n" "$TOKEN"
} > "$tmp"
chmod 0600 "$tmp"
chown root:root "$tmp"
mv "$tmp" "$CRED_FILE"
ok "credentials installed at $CRED_FILE (0600 root:root)"

# ──────────────────────────────────────────────────────────────────────
# Smoke test — single API call to confirm the token works
# ──────────────────────────────────────────────────────────────────────
step "smoke-testing token against GitHub API"
if have curl; then
  http_code="$(curl -sS -o /tmp/.ledger0025-smoke.json -w '%{http_code}' \
    -H "Authorization: Bearer $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/orgs/marvelousempire" 2>/dev/null || echo "000")"
  case "$http_code" in
    200) ok "token authenticates to marvelousempire org" ;;
    401) die "token rejected (401) — bad token or insufficient scope" ;;
    403) die "token forbidden (403) — likely missing read access to marvelousempire" ;;
    404) die "marvelousempire org not visible to this token (404) — check scope" ;;
    *)   warn "smoke test returned HTTP $http_code — token MAY still work for git, proceed and check sync-and-drift.sh logs" ;;
  esac
  rm -f /tmp/.ledger0025-smoke.json
else
  warn "curl not installed — skipping smoke test; run sync-and-drift.sh manually to verify"
fi

# ──────────────────────────────────────────────────────────────────────
# Next-step hint
# ──────────────────────────────────────────────────────────────────────
cat >&2 <<'EOF'

Done. Trigger a sync now to populate the drift report with real SHAs:

  sudo /opt/yousirjuan-sync/sync-and-drift.sh && \
    sudo cat /var/lib/yousirjuan/dual-push-drift-report.json | python3 -m json.tool | head -25

Expected: failures should drop from 88 → 0 (or close to it).
EOF
