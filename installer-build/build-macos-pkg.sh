#!/usr/bin/env bash
# build-macos-pkg.sh — Build (and optionally sign + notarize) the macOS .pkg installer.
#
# Local unsigned build (for testing):
#   bash installer-build/build-macos-pkg.sh
#
# Signed + notarized release (CI or local with credentials):
#   APPLE_TEAM_ID=ABC1234XYZ \
#   APPLE_DEVELOPER_ID_INSTALLER="Developer ID Installer: Your Name (ABC1234XYZ)" \
#   APPLE_ID=hello@yousirjuan.ai \
#   APPLE_APP_PASSWORD=abcd-efgh-ijkl-mnop \
#   bash installer-build/build-macos-pkg.sh
#
# Output: dist/YouSirJuan-macOS-<arch>-<version>.pkg

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$ROOT_DIR/build-tmp"
DIST_DIR="$ROOT_DIR/dist"
VERSION="${VERSION:-0.1.0}"
ARCH="${ARCH:-$(uname -m)}"
[[ "$ARCH" == "x86_64" ]] && ARCH="x64"
PKG_ID="ai.yousirjuan.installer"
PKG_NAME="YouSirJuan-macOS-${ARCH}-${VERSION}.pkg"

note() { printf '\033[2m   %s\033[0m\n' "$*"; }
step() { printf '\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n' "$*"; }
ok()   { printf '   \033[0;32m✓\033[0m %s\n' "$*"; }

[[ "$(uname)" == "Darwin" ]] || { echo "macOS only"; exit 1; }

step "Clean build dir"
rm -rf "$BUILD_DIR" "$DIST_DIR"
mkdir -p "$BUILD_DIR/payload" "$DIST_DIR"

step "Stage payload — what gets installed under /usr/local/yousirjuan/"
PAYLOAD_ROOT="$BUILD_DIR/payload/usr/local/yousirjuan"
mkdir -p "$PAYLOAD_ROOT"
# Copy the runtime files the installer needs at runtime
for d in installers tools vps command-launchers config docs broker openclaw-router; do
  if [[ -d "$ROOT_DIR/$d" ]]; then
    cp -R "$ROOT_DIR/$d" "$PAYLOAD_ROOT/$d"
  fi
done
cp "$ROOT_DIR/bootstrap.sh" "$PAYLOAD_ROOT/"
cp "$ROOT_DIR/README.md" "$PAYLOAD_ROOT/" 2>/dev/null || true
ok "payload staged at $PAYLOAD_ROOT"

step "Postinstall script — what runs on the user's Mac after files are extracted"
mkdir -p "$BUILD_DIR/scripts"
cat > "$BUILD_DIR/scripts/postinstall" <<'POSTINSTALL'
#!/bin/bash
# Triggered automatically when the .pkg finishes installing files.
set -e

INSTALL_ROOT="/usr/local/yousirjuan"

# Symlink the bootstrap entrypoint so users can `bootstrap-yousirjuan` from anywhere
ln -sf "$INSTALL_ROOT/bootstrap.sh" /usr/local/bin/yousirjuan 2>/dev/null || true

# Open the bootstrap in a Terminal window so the user immediately sees the wizard.
osascript -e "tell application \"Terminal\" to do script \"bash $INSTALL_ROOT/bootstrap.sh\"" \
  >/dev/null 2>&1 || true

exit 0
POSTINSTALL
chmod +x "$BUILD_DIR/scripts/postinstall"

step "pkgbuild → component package"
COMPONENT_PKG="$BUILD_DIR/${PKG_ID}-component.pkg"
pkgbuild \
  --root "$BUILD_DIR/payload" \
  --identifier "$PKG_ID" \
  --version "$VERSION" \
  --scripts "$BUILD_DIR/scripts" \
  --install-location "/" \
  "$COMPONENT_PKG"
ok "component pkg built"

step "productbuild → distribution package"
# Distribution XML for the installer UI
DIST_XML="$BUILD_DIR/distribution.xml"
cat > "$DIST_XML" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
  <title>You-Sir Juan</title>
  <organization>ai.yousirjuan</organization>
  <volume-check>
    <allowed-os-versions>
      <os-version min="13.0" />
    </allowed-os-versions>
  </volume-check>
  <choices-outline>
    <line choice="default">
      <line choice="$PKG_ID"/>
    </line>
  </choices-outline>
  <choice id="default"/>
  <choice id="$PKG_ID" visible="false">
    <pkg-ref id="$PKG_ID"/>
  </choice>
  <pkg-ref id="$PKG_ID" version="$VERSION" onConclusion="none">${PKG_ID}-component.pkg</pkg-ref>
</installer-gui-script>
XML

UNSIGNED_PKG="$BUILD_DIR/$PKG_NAME"
productbuild \
  --distribution "$DIST_XML" \
  --package-path "$BUILD_DIR" \
  --version "$VERSION" \
  "$UNSIGNED_PKG"
ok "distribution pkg built (unsigned)"

# ---- Optional: sign + notarize ----
if [[ -n "${APPLE_DEVELOPER_ID_INSTALLER:-}" ]]; then
  step "Signing with Developer ID Installer"
  productsign \
    --sign "$APPLE_DEVELOPER_ID_INSTALLER" \
    "$UNSIGNED_PKG" \
    "$DIST_DIR/$PKG_NAME"
  ok "signed → $DIST_DIR/$PKG_NAME"

  if [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
    step "Submitting to Apple Notary Service"
    xcrun notarytool submit "$DIST_DIR/$PKG_NAME" \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_APP_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait
    ok "notarized"

    step "Stapling notarization ticket"
    xcrun stapler staple "$DIST_DIR/$PKG_NAME"
    ok "stapled — installer will pass Gatekeeper offline"
  else
    note "Skipping notarization (set APPLE_ID, APPLE_APP_PASSWORD, APPLE_TEAM_ID to enable)"
  fi
else
  note "Skipping signing — set APPLE_DEVELOPER_ID_INSTALLER to enable"
  cp "$UNSIGNED_PKG" "$DIST_DIR/$PKG_NAME"
  note "Output: $DIST_DIR/$PKG_NAME (UNSIGNED — Gatekeeper will warn)"
fi

step "SHA256 checksum"
( cd "$DIST_DIR" && shasum -a 256 "$PKG_NAME" > "${PKG_NAME}.sha256" )
ok "$DIST_DIR/${PKG_NAME}.sha256"

step "Done"
ls -lh "$DIST_DIR"
