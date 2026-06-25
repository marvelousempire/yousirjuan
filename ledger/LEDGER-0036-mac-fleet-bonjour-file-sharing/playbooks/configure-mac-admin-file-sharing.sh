#!/usr/bin/env bash
# Admin-only Mac File Sharing: no guest, no whole-disk share, SMB home for admin user only.
set -euo pipefail

ADMIN_USER="${MAC_ADMIN_USER:-${SUDO_USER:-$(id -un)}}"
SHARE_NAME="${MAC_ADMIN_SHARE_NAME:-${ADMIN_USER}}"

if [[ "$(id -u)" -ne 0 ]]; then
  exec sudo MAC_ADMIN_USER="$ADMIN_USER" MAC_ADMIN_SHARE_NAME="$SHARE_NAME" "$0" "$@"
fi

if ! dseditgroup -o checkmember -m "$ADMIN_USER" admin >/dev/null 2>&1; then
  echo "configure-mac-admin-file-sharing: ${ADMIN_USER} is not in group admin" >&2
  exit 1
fi

HOME_DIR="$(dscl . -read "/Users/${ADMIN_USER}" NFSHomeDirectory 2>/dev/null | awk '{print $2}')"
[[ -n "$HOME_DIR" && -d "$HOME_DIR" ]] || HOME_DIR="/Users/${ADMIN_USER}"

echo "==> Admin-only File Sharing on $(scutil --get ComputerName 2>/dev/null || hostname -s)"
echo "    admin user: ${ADMIN_USER}"

if sharing -l -f json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin); sys.exit(0 if any(v.get('path')==sys.argv[1] for v in d.values()) else 1)" "$HOME_DIR" 2>/dev/null; then
  existing="$(sharing -l -f json 2>/dev/null | python3 -c "import json,sys; d=json.load(sys.stdin)
for n,v in d.items():
    if v.get('path')==sys.argv[1]:
        print(n); break" "$HOME_DIR")"
  [[ -n "$existing" ]] && sharing -e "$existing" -S "$SHARE_NAME" -s 001 -g 000 2>/dev/null || true
else
  sharing -a "$HOME_DIR" -S "$SHARE_NAME" -s 001 -g 000 -n "$SHARE_NAME" 2>/dev/null || \
    sharing -a "$HOME_DIR" -S "$SHARE_NAME" -s 001 -g 000
fi

while IFS= read -r name; do
  [[ -z "$name" ]] && continue
  case "$name" in
    "$SHARE_NAME"|"$ADMIN_USER") continue ;;
  esac
  echo "   removing share: ${name}"
  sharing -r "$name" 2>/dev/null || true
done < <(sharing -l -f json 2>/dev/null | python3 -c 'import json,sys
for name in json.load(sys.stdin):
    print(name)' 2>/dev/null)

defaults write /Library/Preferences/com.apple.AppleFileServer guestAccess -bool false 2>/dev/null || true
systemsetup -setremotelogin on 2>/dev/null || true
echo "✓ File Sharing: admin '${ADMIN_USER}' only, guest off"