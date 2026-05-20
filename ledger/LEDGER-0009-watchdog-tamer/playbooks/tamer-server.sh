#!/usr/bin/env bash
# tamer-server.sh — tiny HTTP server exposing Tamer suggestions over Tailscale.
#
# Endpoints:
#   GET /suggestions    → current suggestions JSON (last tamer-tick output)
#   GET /history        → suggestions history (last 100 entries, JSONL)
#   GET /health         → "ok"
#
# Bind: 0.0.0.0:9877 by default (sibling to LEDGER-0008's :9876).
# Tailscale ACL restricts to tag:nephew-tower + tag:dustpan per LEDGER-0008 runbook 03.
#
# Runs alongside the LEDGER-0008 state server. They are independent processes.

set -euo pipefail

PORT="${TAMER_PORT:-9877}"
BIND="${TAMER_BIND:-0.0.0.0}"
STATE_DIR="${HOME}/Library/yousirjuan-state"
SUGGESTIONS_FILE="$STATE_DIR/tamer-suggestions.json"
HISTORY_FILE="$STATE_DIR/tamer-history.jsonl"
SERVER_LOG="${HOME}/Library/Logs/yousirjuan-tamer-server.log"

mkdir -p "$STATE_DIR" "$(dirname "$SERVER_LOG")"
touch "$SUGGESTIONS_FILE" "$HISTORY_FILE" "$SERVER_LOG"

# Seed empty suggestions file so first /suggestions read doesn't 500.
[ -s "$SUGGESTIONS_FILE" ] || \
  printf '{"generated_at": null, "model": null, "suggestions": []}\n' > "$SUGGESTIONS_FILE"

TAMER_SUGGESTIONS_FILE="$SUGGESTIONS_FILE" \
TAMER_HISTORY_FILE="$HISTORY_FILE" \
TAMER_SERVER_LOG="$SERVER_LOG" \
exec python3 -u - "$BIND" "$PORT" <<'PYEOF'
import http.server, json, os, sys, time, traceback

BIND, PORT = sys.argv[1], int(sys.argv[2])
SUGG = os.environ["TAMER_SUGGESTIONS_FILE"]
HIST = os.environ["TAMER_HISTORY_FILE"]
LOG  = os.environ["TAMER_SERVER_LOG"]

def slog(msg):
    with open(LOG, "a") as f:
        f.write(f"[{time.strftime('%Y-%m-%dT%H:%M:%S%z')}] {msg}\n")

def read_text(path):
    try:
        with open(path, "rb") as f:
            return f.read()
    except FileNotFoundError:
        return b""

def tail_jsonl(path, n=100):
    try:
        with open(path, "rb") as f:
            data = f.read()
        lines = [l for l in data.splitlines() if l.strip()]
        return b"\n".join(lines[-n:]) + b"\n"
    except FileNotFoundError:
        return b""

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        slog("%s - %s" % (self.address_string(), fmt % args))

    def _send(self, code, body=b"", ctype="text/plain; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,OPTIONS")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body:
            self.wfile.write(body)

    def do_OPTIONS(self):
        self._send(204)

    def do_GET(self):
        try:
            if self.path == "/suggestions":
                self._send(200, read_text(SUGG) or b'{"suggestions":[]}', "application/json; charset=utf-8")
            elif self.path == "/history":
                self._send(200, tail_jsonl(HIST, 100), "application/x-ndjson; charset=utf-8")
            elif self.path == "/health":
                self._send(200, b"ok\n")
            else:
                self._send(404, b"not found\n")
        except Exception:
            slog("GET %s: %s" % (self.path, traceback.format_exc()))
            self._send(500, b"server error\n")

class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True

slog(f"starting on http://{BIND}:{PORT}")
Server((BIND, PORT), H).serve_forever()
PYEOF
