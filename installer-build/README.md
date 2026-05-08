# installer-build/

Build the signed + notarized macOS `.pkg` installer that the website's
Download button serves.

## Local test build (unsigned, for development)

```bash
bash installer-build/build-macos-pkg.sh
ls dist/
# → YouSirJuan-macOS-arm64-0.1.0.pkg (UNSIGNED — Gatekeeper will warn)
# → YouSirJuan-macOS-arm64-0.1.0.pkg.sha256
```

## Local signed build (requires operator's Apple Developer credentials)

```bash
APPLE_TEAM_ID=ABC1234XYZ \
APPLE_DEVELOPER_ID_INSTALLER="Developer ID Installer: Your Name (ABC1234XYZ)" \
APPLE_ID=hello@yousirjuan.ai \
APPLE_APP_PASSWORD=xxxx-xxxx-xxxx-xxxx \
bash installer-build/build-macos-pkg.sh
```

## CI release (the real production path)

Tag a release:

```bash
git tag v0.1.0
git push origin v0.1.0
```

The `.github/workflows/release-installer.yml` workflow:
1. Imports the signing certificate from `APPLE_DEVELOPER_CERT_P12` secret
2. Builds + signs + notarizes the `.pkg` (both arm64 + x64)
3. Uploads the `.pkg` files to a **public** Release on `marvelousempire/yousirjuan-ai`
4. The website's `/download` page links resolve

## Required GitHub Secrets

Add these in the **private** `yousirjuan` repo's Settings → Secrets and variables → Actions → New repository secret.

| Secret | Source / how to get it |
|---|---|
| `APPLE_TEAM_ID` | Apple Developer Account → Membership tab. 10-char string like `ABC1234XYZ`. |
| `APPLE_DEVELOPER_ID_INSTALLER` | Full common name of your "Developer ID Installer" certificate. Get from Keychain Access → My Certificates. Looks like `Developer ID Installer: Your Name (ABC1234XYZ)`. |
| `APPLE_DEVELOPER_ID_APPLICATION` | Same but for "Developer ID Application" cert (used for signing the binary inside the .pkg). |
| `APPLE_ID` | Your Apple ID email. |
| `APPLE_APP_PASSWORD` | App-specific password from https://appleid.apple.com/account/manage → Sign-In and Security → App-Specific Passwords. |
| `APPLE_DEVELOPER_CERT_P12` | Base64-encoded `.p12` export of your "Developer ID Installer" certificate **including its private key**. Export from Keychain Access (right-click → Export, set password). Then `base64 < cert.p12 \| pbcopy` and paste into the secret. |
| `APPLE_DEVELOPER_CERT_PASSWORD` | The passphrase you set when exporting the .p12. |
| `PUBLIC_REPO_TOKEN` | Fine-grained GitHub PAT with `contents: write` permission on `marvelousempire/yousirjuan-ai`. Create at https://github.com/settings/tokens?type=beta. |

## How notarization works (one-time mental model)

1. We build the .pkg locally (or in CI on a macOS runner).
2. We sign it with the Developer ID Installer cert (proof: this is from us).
3. We submit the signed .pkg to Apple's notary service (`xcrun notarytool submit`).
4. Apple scans for malware (~2 min). If clean, returns a "ticket".
5. We staple the ticket to the .pkg (`xcrun stapler staple`). Now the .pkg includes proof Apple cleared it.
6. End user downloads the stapled .pkg. macOS verifies the staple offline. **No "unidentified developer" warning.** Just install.

## What the .pkg contains

- Files extracted to `/usr/local/yousirjuan/` (the entire repo bootstrap layout)
- A symlink at `/usr/local/bin/yousirjuan` → `bootstrap.sh` (so `yousirjuan` becomes a CLI command)
- A postinstall script that opens Terminal and runs `bootstrap.sh` to start the wizard
- Standard `pkgutil` registration (so `pkgutil --pkgs | grep yousirjuan` shows it)

## Uninstall a previously installed .pkg

```bash
sudo pkgutil --forget ai.yousirjuan.installer
sudo rm -rf /usr/local/yousirjuan
sudo rm -f /usr/local/bin/yousirjuan
# Then run the existing uninstall script for the AI services themselves:
bash /usr/local/yousirjuan/tools/uninstall.sh   # if you still have it
```

(Or use the .command launcher in `/Applications/Utilities/` if we add a desktop shortcut later.)
