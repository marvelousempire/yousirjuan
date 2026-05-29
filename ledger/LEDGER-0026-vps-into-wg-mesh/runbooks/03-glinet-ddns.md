# 03 — Enable DDNS on the GL-MT6000

## Why

Off-LAN WG peers need a stable hostname for their `Endpoint` field. ISP WAN IPs change; DDNS keeps a hostname pointed at the current IP. GL.iNet's built-in DDNS gives the family a free `<uuid>.glddns.com` hostname with no third-party account.

## Steps

In the GL.iNet admin UI at `https://192.168.8.1` (or `http://router.asus.com` if that resolves):

1. **Applications → Dynamic DNS** (NOT Cloud Services — DDNS lives under Applications in v4.8.4 firmware).
2. Enable the DDNS toggle.
3. Accept Terms of Service + Privacy Policy.
4. Click **Apply**.
5. Note the auto-assigned hostname (format: `<uuid>.glddns.com`, e.g. `xr5899d.glddns.com`).
6. Optionally run the **DDNS Test** to verify resolution matches the WAN IP.

## Success criteria

- `dig +short <hostname>.glddns.com` returns the Verizon WAN IP (currently `97.164.202.176`)
- The DDNS Test panel shows a green "correctly resolved" banner

## Undo

In the same panel, toggle DDNS off and Apply. The hostname is released back to GL.iNet's pool.

## Security note

Enabling DDNS surfaces a public hostname for the home network. The "Security Settings" prompt that appears alongside DDNS asks whether to expose HTTPS and SSH Remote Access — **disable both** unless you have a specific reason. Admin UI continues to work fine on LAN.
