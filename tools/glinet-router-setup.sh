#!/usr/bin/env bash
# glinet-router-setup.sh — Configure any GL.iNet router (Flint 2 / MT6000,
# Slate AX / AXT1800, Brume 2, etc. — all run the same GL.iNet OpenWRT stack)
# to host the private AI stack on a stable LAN IP, plus guide you through
# WireGuard + AdGuard Home setup.
#
# Recommended topology if you have BOTH a Flint 2 and a Slate AX:
#   • Run this script against the Flint 2 — it's your always-on home base
#     (more CPU + RAM = headroom for AdGuard + WireGuard concurrently)
#   • Use the Slate AX as a travel router; configure WireGuard *Client* on
#     it pointing at the Flint 2's WireGuard *Server*. Then any device
#     connected to the Slate AX in a hotel/cafe transparently reaches your
#     home AI stack — no per-device WireGuard config needed.
#
# Run this on the Mac that's running the AI stack (NOT on the router).
#
#   bash glinet-router-setup.sh
#
# What it does automatically (over SSH):
#   • Adds a DHCP reservation so this Mac always gets the same LAN IP
#   • Optionally enables AdGuard Home (DNS-level ad/tracker block)
#
# What it just GUIDES you through (because the GL.iNet GUI is faster):
#   • WireGuard Server (so you can reach the AI from your phone on cellular)
#
# The router's default WAN firewall already blocks unsolicited inbound, so
# the AI services are not exposed to the internet unless you create port
# forwards (don't).

set -euo pipefail

# ---- helpers ---------------------------------------------------------------
step()  { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note()  { printf "    \033[2m%s\033[0m\n" "$*"; }
ok()    { printf "    \033[0;32m✓\033[0m %s\n" "$*"; }
warn()  { printf "    \033[0;33m!\033[0m %s\n" "$*"; }
die()   { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }
ask()   { local prompt="$1" default="${2:-}" answer; read -r -p "    $prompt${default:+ [$default]}: " answer; printf '%s' "${answer:-$default}"; }

# ---- 1. Discover the router + this Mac ------------------------------------

step "Detecting the router"

# Default route's gateway IP — works on macOS
ROUTER_IP_DEFAULT="$(route -n get default 2>/dev/null | awk '/gateway:/ {print $2}')"
if [[ -z "$ROUTER_IP_DEFAULT" ]]; then
  ROUTER_IP_DEFAULT="192.168.8.1"
fi

ROUTER_IP="$(ask "Router IP" "$ROUTER_IP_DEFAULT")"
SSH_USER="$(ask "SSH user" "root")"

# Quick reachability check
if ! ping -c 1 -W 1000 "$ROUTER_IP" >/dev/null 2>&1; then
  die "Can't reach $ROUTER_IP. Make sure you're connected to the Slate AX's network."
fi
ok "Router reachable at $ROUTER_IP"

step "Detecting this Mac on the LAN"

# Find the active interface (the one with the default route)
IFACE="$(route -n get default 2>/dev/null | awk '/interface:/ {print $2}')"
[[ -n "$IFACE" ]] || die "Couldn't detect default network interface."

MY_IP="$(ipconfig getifaddr "$IFACE" 2>/dev/null || true)"
MY_MAC="$(ifconfig "$IFACE" 2>/dev/null | awk '/ether/ {print $2}')"

[[ -n "$MY_MAC" ]] || die "Couldn't read MAC address on $IFACE."
ok "Interface $IFACE — IP $MY_IP, MAC $MY_MAC"

# Suggest a static IP based on the current subnet — pick .50 in the same /24
DEFAULT_STATIC="$(echo "$MY_IP" | awk -F. '{printf "%s.%s.%s.50", $1, $2, $3}')"
STATIC_IP="$(ask "Static IP to reserve for this Mac" "$DEFAULT_STATIC")"
HOSTNAME_LABEL="$(ask "Hostname label for the reservation" "ai-server")"

cat <<EOF

────────────────────────────────────────────────────────────────────
  About to configure on $ROUTER_IP via SSH:

    DHCP reservation:
      MAC      $MY_MAC
      IP       $STATIC_IP
      Hostname $HOSTNAME_LABEL

────────────────────────────────────────────────────────────────────
EOF
read -r -p "    Proceed? [y/N] " yn
[[ "$yn" =~ ^[Yy]$ ]] || die "Aborted."

# ---- 2. Add the DHCP reservation over SSH ---------------------------------

step "Adding DHCP reservation (SSH will prompt for the router password)"

# All-in-one remote script. Runs on the router via SSH. POSIX sh only — no
# bash-isms, OpenWRT uses BusyBox.
ssh -o StrictHostKeyChecking=accept-new "$SSH_USER@$ROUTER_IP" 'sh -s' <<REMOTE
set -e
MAC="$MY_MAC"
IP="$STATIC_IP"
NAME="$HOSTNAME_LABEL"

# Remove any existing reservation for this MAC (idempotent re-runs)
COUNT=\$(uci show dhcp 2>/dev/null | grep -c "^dhcp.@host\[" || true)
i=0
while [ \$i -lt \$COUNT ]; do
  EXISTING_MAC=\$(uci -q get "dhcp.@host[\$i].mac" || echo "")
  if [ "\$(echo \$EXISTING_MAC | tr 'A-Z' 'a-z')" = "\$(echo \$MAC | tr 'A-Z' 'a-z')" ]; then
    uci delete "dhcp.@host[\$i]"
    echo "  removed existing reservation for \$MAC"
    break
  fi
  i=\$((i + 1))
done

# Add fresh reservation
uci add dhcp host >/dev/null
uci set dhcp.@host[-1].name="\$NAME"
uci set dhcp.@host[-1].mac="\$MAC"
uci set dhcp.@host[-1].ip="\$IP"
uci commit dhcp

# Restart dnsmasq so it takes effect
/etc/init.d/dnsmasq restart >/dev/null

echo "  reservation written + dnsmasq restarted"
REMOTE

ok "Static IP $STATIC_IP reserved for $MY_MAC"
note "Renew DHCP on this Mac so it picks up the new IP:"
note "  sudo ipconfig set $IFACE BOOTP && sudo ipconfig set $IFACE DHCP"
note "(or just toggle Wi-Fi off/on)"

# ---- 3. Optional: AdGuard Home --------------------------------------------

step "AdGuard Home (DNS ad/tracker blocking, LAN-wide)"
read -r -p "    Enable AdGuard Home on the router? [y/N] " yn_ag
if [[ "$yn_ag" =~ ^[Yy]$ ]]; then
  ssh "$SSH_USER@$ROUTER_IP" 'sh -s' <<'REMOTE' || warn "AdGuard enable failed (it may already be on, or not installed on this firmware)"
set -e
if [ -x /etc/init.d/adguardhome ]; then
  /etc/init.d/adguardhome enable
  /etc/init.d/adguardhome start
  echo "  adguardhome enabled + started"
else
  echo "  adguardhome service not found — enable it via the GL.iNet UI:"
  echo "    Applications → AdGuard Home → toggle on"
fi
REMOTE
  ok "AdGuard Home: visit http://$ROUTER_IP/ → Applications → AdGuard Home to configure"
else
  note "Skipped AdGuard Home"
fi

# ---- 4. Guide: WireGuard Server -------------------------------------------

step "WireGuard Server setup (manual — easier in the GL.iNet UI)"
cat <<EOF

    Why: lets you reach Open WebUI / OpenClaw from your phone on cellular,
    or from anywhere, WITHOUT exposing them to the public internet.

    Steps in the GL.iNet UI:
      1. Open http://$ROUTER_IP/ in your browser
      2. VPN → WireGuard Server → Initialize Server (uses defaults, fine)
      3. Click "Start" — server is now running on UDP 51820
      4. Click "+ Add a New User" → enter a name (e.g. "phone")
      5. Tap the "Configurations" tab → reveal the QR code
      6. On your phone:
           • Install the WireGuard app (App Store / Play Store)
           • Tap "+" → "Scan from QR code"
           • Toggle the tunnel ON
      7. To reach your AI from the phone:
           Open WebUI:        http://$STATIC_IP:3000
           OpenClaw dash:     http://$STATIC_IP:18789

    Notes:
      • The router's WireGuard server uses Dynamic DNS (configurable in the
        same screen) so you don't need a static public IP from your ISP.
      • Make sure the WireGuard config's "Allowed IPs" includes your LAN
        subnet (e.g. ${STATIC_IP%.*}.0/24) — the GL.iNet UI does this by default.

EOF

# ---- 5. Summary -----------------------------------------------------------

cat <<EOF

────────────────────────────────────────────────────────────────────
  DONE.
────────────────────────────────────────────────────────────────────

  This Mac's reserved LAN IP:    $STATIC_IP
  Open WebUI:                    http://$STATIC_IP:3000
  OpenClaw dashboard:            http://$STATIC_IP:18789
  Router admin:                  http://$ROUTER_IP/

  After WireGuard setup (above), the same URLs work from anywhere
  while the WireGuard tunnel is on.

  The router's WAN firewall blocks unsolicited inbound by default.
  DON'T add port forwards for 3000 / 11434 / 18789 — they would
  expose your AI to the public internet.

EOF
