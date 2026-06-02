# 02 — Issue + install a device cert (Mac / iOS / iPad)

One client cert per family device. Without it, the mTLS cassettes refuse the
connection. ~2 minutes per device.

## Issue (on the CA host)
```bash
sudo FAMILY_CA_DIR=/etc/jailynmarvin-ca bash playbooks/family-ca.sh issue-device avery-macbook
# → /etc/jailynmarvin-ca/issued/avery-macbook.p12  (set an export password when prompted)
```

## Install
- **macOS:** AirDrop/scp the `.p12` to the Mac → double-click → add to **login keychain** → enter the export password. Safari/Chrome will offer it automatically to `*.jailynmarvin.com`.
- **iOS / iPadOS:** AirDrop the `.p12` → Settings → **Profile Downloaded** → Install → enter the export password. Safari presents it automatically.
- **curl / CLI:** use `--cert issued/<name>.crt --key issued/<name>.key`.

## Success criteria
```bash
curl --cert /path/avery-macbook.crt --key /path/avery-macbook.key https://nephew.jailynmarvin.com/   # 200 / SSO
curl https://nephew.jailynmarvin.com/                                                                # TLS refused
```

## Undo / lost device
```bash
sudo bash playbooks/family-ca.sh revoke avery-macbook   # regenerates CRL
# redeploy crl.pem to the edges so the revoked cert is rejected
```
