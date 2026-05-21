#!/usr/bin/env bash
# install.sh — install LEDGER-0020 defense layers on VPS.
#
# Lays down:
#   /usr/local/lib/yousirjuan/check-intent-before-start.sh  (Layer B hook)
#   /usr/local/lib/yousirjuan/intent-aware-unmask.sh        (Layer C wrapper)
#   /etc/yousirjuan/intent-unit-map.json                    (unit↔topic mapping)
#
# Then for each unit listed in the map, installs a systemd drop-in:
#   /etc/systemd/system/<unit>.d/50-yousirjuan-intent-check.conf
# That runs check-intent-before-start.sh as ExecStartPre.
#
# Layer A (alert-watch extension on iMac) + Layer D (auto-heal in drift checker)
# are documented in this PR's README and shipped as separate edits to the
# LEDGER-0015 and LEDGER-0019 scripts on main.

set -euo pipefail
[[ $EUID -eq 0 ]] || { echo "must run as root"; exit 1; }

REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
LIB_DIR="/usr/local/lib/yousirjuan"
ETC_DIR="/etc/yousirjuan"

CHECK_SRC="${REPO_ROOT}/ledger/LEDGER-0020-intent-defense-in-depth/playbooks/check-intent-before-start.sh"
UNMASK_SRC="${REPO_ROOT}/ledger/LEDGER-0020-intent-defense-in-depth/playbooks/intent-aware-unmask.sh"
MAP_SRC="${REPO_ROOT}/ledger/LEDGER-0020-intent-defense-in-depth/artifacts/intent-unit-map.json"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }

case "${1:-install}" in
  install)
    step "Installing Layer B (ExecStartPre hook) + Layer C (intent-aware-unmask wrapper)"
    mkdir -p "$LIB_DIR" "$ETC_DIR"
    install -m 0755 "$CHECK_SRC"  "$LIB_DIR/check-intent-before-start.sh"
    install -m 0755 "$UNMASK_SRC" "$LIB_DIR/intent-aware-unmask.sh"
    ok "scripts installed to $LIB_DIR"

    if [[ ! -f "$ETC_DIR/intent-unit-map.json" ]]; then
      install -m 0644 "$MAP_SRC" "$ETC_DIR/intent-unit-map.json"
      ok "installed default unit map at $ETC_DIR/intent-unit-map.json"
    else
      ok "unit map already exists (preserving operator edits)"
    fi

    step "  installing ExecStartPre drop-ins for each unit in the map"
    python3 -c "import json; m=json.load(open('$ETC_DIR/intent-unit-map.json'));[print(u) for u in m if not u.startswith('_')]" | \
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      drop_in_dir="/etc/systemd/system/${unit}.d"
      drop_in_file="$drop_in_dir/50-yousirjuan-intent-check.conf"
      mkdir -p "$drop_in_dir"
      cat > "$drop_in_file" <<EOF
# LEDGER-0020 — refuse start if intent file says this unit should be stopped.
[Service]
ExecStartPre=$LIB_DIR/check-intent-before-start.sh %n
EOF
      printf "  ✓ %s\n" "$drop_in_file"
    done

    systemctl daemon-reload
    ok "systemd daemon-reload"

    printf "\n${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
    printf "${GREEN}LEDGER-0020 Layers B + C installed.${NC}\n"
    printf "${GREEN}══════════════════════════════════════════════════════════════════════${NC}\n"
    printf "Test that Layer B works:\n"
    printf "  ${YELLOW}sudo systemctl start n8n-nephew.service${NC}\n"
    printf "  → if n8n-stopped intent file exists: start FAILS with REFUSED message\n"
    printf "  → if no intent file: start proceeds normally\n\n"
    printf "Use Layer C to legitimately override:\n"
    printf "  ${YELLOW}sudo bash $LIB_DIR/intent-aware-unmask.sh n8n-nephew.service${NC}\n"
    printf "  → atomically removes intent + unmasks + starts\n\n"
    ;;
  uninstall)
    step "Uninstalling LEDGER-0020"
    # Find every drop-in we created
    find /etc/systemd/system -name "50-yousirjuan-intent-check.conf" -exec rm -f {} \; -print
    rm -f "$LIB_DIR/check-intent-before-start.sh" "$LIB_DIR/intent-aware-unmask.sh"
    systemctl daemon-reload
    ok "uninstalled (unit map preserved at $ETC_DIR/intent-unit-map.json)"
    ;;
  test)
    # Simulate by calling check-intent on each known unit
    step "Layer B test: simulating ExecStartPre check for each protected unit"
    python3 -c "import json; m=json.load(open('$ETC_DIR/intent-unit-map.json'));[print(u) for u in m if not u.startswith('_')]" | \
    while read -r unit; do
      [[ -z "$unit" ]] && continue
      if bash "$LIB_DIR/check-intent-before-start.sh" "$unit" 2>&1; then
        ok "$unit: would ALLOW start (no intent or intent matches)"
      else
        warn "$unit: would REFUSE start (intent file says stopped)"
      fi
    done
    ;;
  *) echo "usage: $0 {install|uninstall|test}";;
esac
