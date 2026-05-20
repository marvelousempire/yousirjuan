#!/usr/bin/env bash
# watchdog-state-server.sh — tiny HTTP server exposing watchdog state + settings
#
# Serves the iMac watchdog's JSON state + log tail over HTTP on the Tailscale
# interface so the Nephew Control Tower (running on the VPS) and DustPan
# (running on a Mac) can read live state and update settings without
# needing direct filesystem access.
#
# Endpoints:
#   GET  /state    → application/json (contents of vps-watchdog.json)
#   GET  /logs     → text/plain        (last 200 lines of yousirjuan-vps-watchdog.log)
#   GET  /settings → application/json (current settings from vps-watchdog.conf)
#   POST /settings → updates vps-watchdog.conf; watchdog re-reads on next tick
#   GET  /health   → text/plain "ok"  (for the Nephew status card heartbeat)
#
# Bind: 0.0.0.0:9876 by default. Tailscale ACL OR pf rule should restrict to tailnet.
# No auth on read endpoints (state is non-sensitive). POST /settings requires
# the bearer token in ~/.config/yousirjuan/watchdog-server.env (chmod 600).
#
# Idempotent. Logs to ~/Library/Logs/yousirjuan-watchdog-server.log.

set -euo pipefail

PORT="${WATCHDOG_PORT:-9876}"
BIND="${WATCHDOG_BIND:-0.0.0.0}"
STATE_FILE="${HOME}/Library/yousirjuan-state/vps-watchdog.json"
LOG_FILE="${HOME}/Library/Logs/yousirjuan-vps-watchdog.log"
CONF_FILE="${HOME}/Library/yousirjuan-state/vps-watchdog.conf"
SERVER_LOG="${HOME}/Library/Logs/yousirjuan-watchdog-server.log"
TOKEN_FILE="${HOME}/.config/yousirjuan/watchdog-server.env"

mkdir -p "$(dirname "$STATE_FILE")" "$(dirname "$SERVER_LOG")"
touch "$STATE_FILE" "$LOG_FILE" "$SERVER_LOG"

# Seed default conf file on first run.
if [[ ! -f "$CONF_FILE" ]]; then
  cat > "$CONF_FILE" <<'EOF'
{
  "dry_run": true,
  "domain": "yousirjuan.ai",
  "vps_ip": "72.167.151.251",
  "failover_ip": "",
  "targets": [
    {"sub": "hello",    "url": "https://hello.yousirjuan.ai/"},
    {"sub": "nephew",   "url": "https://nephew.yousirjuan.ai/"},
    {"sub": "clinic",   "url": "https://clinic.yousirjuan.ai/"},
    {"sub": "git",      "url": "https://git.yousirjuan.ai/"},
    {"sub": "workflow", "url": "https://workflow.yousirjuan.ai/"}
  ],
  "strikes_to_swap": 3,
  "strikes_to_revert": 3,
  "hysteresis_min_seconds": 1800,
  "probe_timeout_seconds": 10
}
EOF
fi

# Load bearer token if present.
TOKEN=""
if [[ -f "$TOKEN_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$TOKEN_FILE" 2>/dev/null || true
  TOKEN="${WATCHDOG_TOKEN:-}"
fi

ts() { date '+%Y-%m-%dT%H:%M:%S%z'; }
slog() { printf "[%s] %s\n" "$(ts)" "$*" >>"$SERVER_LOG"; }

slog "starting on ${BIND}:${PORT}; state=${STATE_FILE} conf=${CONF_FILE}"

# Use python3's http.server for portability; macOS ships it.
WATCHDOG_STATE_FILE="$STATE_FILE" \
WATCHDOG_LOG_FILE="$LOG_FILE" \
WATCHDOG_CONF_FILE="$CONF_FILE" \
WATCHDOG_TOKEN="$TOKEN" \
WATCHDOG_SERVER_LOG="$SERVER_LOG" \
exec python3 -u - "$BIND" "$PORT" <<'PYEOF'
import http.server, json, os, sys, time, traceback

BIND, PORT = sys.argv[1], int(sys.argv[2])
STATE = os.environ["WATCHDOG_STATE_FILE"]
LOGF  = os.environ["WATCHDOG_LOG_FILE"]
CONF  = os.environ["WATCHDOG_CONF_FILE"]
TOKEN = os.environ.get("WATCHDOG_TOKEN") or ""
SLOG  = os.environ["WATCHDOG_SERVER_LOG"]

def slog(msg):
    with open(SLOG, "a") as f:
        f.write(f"[{time.strftime('%Y-%m-%dT%H:%M:%S%z')}] {msg}\n")

def read_text(path, max_bytes=None):
    try:
        with open(path, "rb") as f:
            data = f.read()
            if max_bytes and len(data) > max_bytes:
                data = data[-max_bytes:]
            return data
    except FileNotFoundError:
        return b""

def tail_lines(path, n):
    try:
        with open(path, "rb") as f:
            data = f.read()
        return b"\n".join(data.splitlines()[-n:]) + b"\n"
    except FileNotFoundError:
        return b""

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):  # silence default stderr noise
        slog("%s - %s" % (self.address_string(), fmt % args))

    def _send(self, code, body=b"", ctype="text/plain; charset=utf-8", extra=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization")
        if extra:
            for k, v in extra.items():
                self.send_header(k, v)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)

    def do_OPTIONS(self):
        self._send(204)

    def do_GET(self):
        try:
            if self.path == "/state":
                body = read_text(STATE) or b"{}"
                self._send(200, body, "application/json; charset=utf-8")
            elif self.path == "/logs":
                body = tail_lines(LOGF, 200)
                self._send(200, body, "text/plain; charset=utf-8")
            elif self.path == "/settings":
                body = read_text(CONF) or b"{}"
                self._send(200, body, "application/json; charset=utf-8")
            elif self.path == "/health":
                self._send(200, b"ok\n")
            else:
                self._send(404, b"not found\n")
        except Exception:
            slog("GET %s: %s" % (self.path, traceback.format_exc()))
            self._send(500, b"server error\n")

    def do_POST(self):
        try:
            if self.path != "/settings":
                self._send(404, b"not found\n"); return
            # Require bearer token if one is configured.
            if TOKEN:
                auth = self.headers.get("Authorization", "")
                if auth != f"Bearer {TOKEN}":
                    self._send(401, b"unauthorized\n"); return
            n = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(n) if n > 0 else b""
            try:
                obj = json.loads(raw or b"{}")
            except json.JSONDecodeError:
                self._send(400, b"invalid json\n"); return
            # Minimal validation. Required keys: dry_run, targets, vps_ip.
            for required in ("dry_run", "targets", "vps_ip"):
                if required not in obj:
                    self._send(400, f"missing field: {required}\n".encode()); return
            if not isinstance(obj["targets"], list):
                self._send(400, b"targets must be a list\n"); return
            # If going live (dry_run=false), require failover_ip.
            if obj.get("dry_run") is False and not obj.get("failover_ip"):
                self._send(400, b"failover_ip required when dry_run=false\n"); return
            # Write atomically.
            tmp = CONF + ".tmp"
            with open(tmp, "w") as f:
                json.dump(obj, f, indent=2)
            os.replace(tmp, CONF)
            slog("POST /settings: updated; dry_run=%s targets=%d" % (obj.get("dry_run"), len(obj["targets"])))
            self._send(200, b'{"ok":true}\n', "application/json; charset=utf-8")
        except Exception:
            slog("POST %s: %s" % (self.path, traceback.format_exc()))
            self._send(500, b"server error\n")

class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True

srv = Server((BIND, PORT), H)
slog(f"listening on http://{BIND}:{PORT}")
try:
    srv.serve_forever()
except KeyboardInterrupt:
    slog("stopped (SIGINT)")
PYEOF
