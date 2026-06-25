#!/usr/bin/env bash
# Install LaunchAgents for hostname-only auto-mounts on fivemac.
set -euo pipefail

LEDGER="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
PB="$LEDGER/playbooks"
LOG_DIR="${HOME}/.nephew/logs"
mkdir -p "$LOG_DIR"

install_plist() {
  local label="$1" script="$2" interval="$3" extra_args="${4:-}"
  local plist="$HOME/Library/LaunchAgents/${label}.plist"
  cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>${label}</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>${script}</string>
    ${extra_args}
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>StartInterval</key>
  <integer>${interval}</integer>
  <key>StandardOutPath</key>
  <string>${LOG_DIR}/${label}.out.log</string>
  <key>StandardErrorPath</key>
  <string>${LOG_DIR}/${label}.err.log</string>
</dict>
</plist>
EOF
  launchctl bootout "gui/$(id -u)/${label}" 2>/dev/null || launchctl unload "$plist" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$plist" 2>/dev/null || launchctl load -w "$plist"
  echo "✓ ${label}"
}

install_plist "com.marvelousempire.nephew-spark-mounts" "$PB/ensure-nephew-spark-mounts.sh" 300 ""
install_plist "com.marvelousempire.mac-fleet-mounts" "$PB/ensure-mac-fleet-mounts.sh" 600 ""

echo "Logs: ${LOG_DIR}/com.marvelousempire.*.err.log"