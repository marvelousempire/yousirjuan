#!/usr/bin/env bash
# Copy bootstrap kit onto mounted onemac/twomac shares (when SMB is up).
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
KIT_NAME="FleetBootstrap-LEDGER-0036"
STAMP="$(date '+%Y-%m-%d')"

drop() {
  local mount="$1" host_tag="$2"
  [[ -d "$mount" ]] || { echo "○ ${host_tag}: ${mount} not mounted — skip"; return 1; }
  local dest="${mount}/${KIT_NAME}"
  mkdir -p "$dest"
  cp "$HERE/bootstrap-mac-fleet-ssh.sh" "$HERE/configure-mac-admin-file-sharing.sh" \
     "$HERE/configure-mac-bonjour-name.sh" "$dest/"
  chmod +x "$dest"/*.sh
  cat > "$dest/RUN-ME.txt" <<EOF
Fleet bootstrap — ${STAMP}
Run once in Terminal ON THIS MAC (${host_tag}):

  cd "${KIT_NAME}"
  bash bootstrap-mac-fleet-ssh.sh

Then on fivemac:
  install-fleet-sharing
EOF
  echo "✓ dropped bootstrap kit → ${dest}"
}

drop "/Volumes/SeverD" "onemac"
drop "${HOME}/Volumes/onemac-severd" "onemac-alt"
drop "${HOME}/Volumes/twomac-metal-hd" "twomac"
drop "/Volumes/Metal HD" "twomac-alt"