# 05 — Add a family member's device (mTLS badge)

Each person/device gets its own client cert so it can open the mTLS-gated cassettes
(nephew, bank, search). One cert per device = individually revocable if a device is lost.

## 1. Mint the cert (on the CA host — the VPS)
```
ssh nephew-ct   # or however you reach the VPS
sudo FAMILY_CA_DIR=/etc/jailynmarvin-ca bash <repo>/ledger/LEDGER-0031-cassette-edge-mtls-wireguard/playbooks/family-ca.sh issue-device <name-device>
# e.g. issue-device jailyn-iphone  → /etc/jailynmarvin-ca/issued/jailyn-iphone.{crt,key,p12}
```
Copy the `.crt` + `.key` (and `.p12` if it imports) to the person's Mac.

## 2. Make the `.p12` macOS/iOS-compatible (IMPORTANT)
OpenSSL 3 (the VPS) writes `.p12` files with modern encryption that **macOS Keychain
rejects** (`OSStatus -26276`). Regenerate it **on a Mac** (LibreSSL = compatible format):
```
cd ~/Downloads
/usr/bin/openssl pkcs12 -export -inkey <name-device>.key -in <name-device>.crt \
  -name "<name-device> @ jailynmarvin" -out <name-device>.p12 -passout pass:<PICK-A-PASSWORD>
# verify it opens:
/usr/bin/openssl pkcs12 -info -in <name-device>.p12 -passin pass:<PICK-A-PASSWORD> -nokeys | grep friendlyName
```

## 3. Install
- **Mac:** double-click `<name-device>.p12` → **login** keychain → enter the password.
- **iPhone/iPad:** AirDrop the `.p12` → Settings shows **"Profile Downloaded"** → Install → device passcode → cert password.
- **First site visit:** Safari shows *"Select a certificate"* → pick `<name-device> @ jailynmarvin` → **Always Allow**.

## Success criteria
```
curl --cert <name-device>.crt --key <name-device>.key https://search.jailynmarvin.com/   # serves
curl https://search.jailynmarvin.com/                                                     # 400 (blocked)
```
Browser on the device opens nephew/bank/search after picking the cert once.

## Revoke (lost device)
```
sudo bash <repo>/.../playbooks/family-ca.sh revoke <name-device>   # regenerates CRL
# redeploy crl.pem to the edge so the revoked cert is rejected
```
