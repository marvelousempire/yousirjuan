#!/usr/bin/env bash
# apply-all.sh — run 01 → 02 → 03 in safe order with operator confirmation.
#
# Order rationale:
#   1. GitLab caps first — biggest immediate impact, gives instant headroom
#   2. sshd OOM protect — makes the host safer for everything that follows
#   3. Swap resize last — uses ~30-60s and changes /etc/fstab; do it once everything else is steady

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
banner() { printf "\n${BLUE}══════════════════════════════════════════════════════════════════════${NC}\n${BLUE}%s${NC}\n${BLUE}══════════════════════════════════════════════════════════════════════${NC}\n\n" "$*"; }

banner "LEDGER-0011 — VPS memory hardening (apply all)"
printf "Host: $(hostname)  ($(uname -srm))\n"
printf "Memory:\n"
free -h | sed 's/^/  /'
printf "\n"

read -rp "Proceed with all 3 hardening steps? [y/N] " ans
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  printf "${YELLOW}aborted by operator${NC}\n"; exit 1
fi

banner "Step 1/3 — GitLab Puma + Sidekiq memory caps"
bash "$SCRIPT_DIR/01-gitlab-memory-caps.sh" apply

banner "Step 2/3 — sshd OOM protection"
bash "$SCRIPT_DIR/02-sshd-oom-protect.sh" apply

banner "Step 3/3 — Resize swap to 8 GB"
bash "$SCRIPT_DIR/03-double-swap.sh" apply

banner "All three hardening steps applied"
printf "Post-state memory:\n"
free -h | sed 's/^/  /'
printf "\nNext: monitor for 24 h. If a third OOM cascade happens within 24 h with\n"
printf "      these caps in place, schedule the RAM upgrade (8 GB → 16 GB) on the\n"
printf "      GoDaddy VPS plan.\n\n"
