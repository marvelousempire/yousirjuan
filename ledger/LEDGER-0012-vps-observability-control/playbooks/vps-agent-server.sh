#!/usr/bin/env bash
# vps-agent-server.sh — VPS-side observability + control daemon for DustPan.
#
# Endpoints:
#   GET  /system     → JSON: uptime, load, memory, swap, disk
#   GET  /processes  → JSON: top 20 by CPU + top 20 by MEM
#   GET  /docker     → JSON: docker ps output (containers, status, ports)
#   GET  /sites      → JSON: status of each yousirjuan.ai subdomain (curl probe)
#   GET  /health     → "ok"
#   POST /kill       → {pid} kill a process (requires Bearer token)
#   POST /docker/stop  → {name} docker stop a container (requires Bearer token)
#   POST /docker/start → {name} docker start a container (requires Bearer token)
#
# Listens on 0.0.0.0:9878 by default. Tailscale ACL restricts to tag:dustpan + tag:nephew-tower.
# Bearer token at /etc/yousirjuan/vps-agent.env (chmod 600, generated on install).
#
# Runs as the abrownsanta user via systemd. Cannot kill root processes
# unless escalated (which we don't do — operator can SSH for that).

set -euo pipefail

PORT="${VPS_AGENT_PORT:-9878}"
BIND="${VPS_AGENT_BIND:-0.0.0.0}"
TOKEN_FILE="${VPS_AGENT_TOKEN_FILE:-/etc/yousirjuan/vps-agent.env}"
LOG_FILE="${VPS_AGENT_LOG:-/var/log/yousirjuan-vps-agent.log}"

# Load token if available; otherwise POST endpoints are disabled.
TOKEN=""
[ -f "$TOKEN_FILE" ] && { source "$TOKEN_FILE" 2>/dev/null || true; TOKEN="${VPS_AGENT_TOKEN:-}"; }

mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true
touch "$LOG_FILE" 2>/dev/null || LOG_FILE="/tmp/yousirjuan-vps-agent.log"

VPS_AGENT_TOKEN="$TOKEN" \
VPS_AGENT_LOG="$LOG_FILE" \
exec python3 -u - "$BIND" "$PORT" <<'PYEOF'
import http.server, json, os, subprocess, sys, time, traceback

BIND, PORT = sys.argv[1], int(sys.argv[2])
TOKEN = os.environ.get("VPS_AGENT_TOKEN") or ""
LOG = os.environ["VPS_AGENT_LOG"]

def slog(msg):
    line = f"[{time.strftime('%Y-%m-%dT%H:%M:%S%z')}] {msg}\n"
    try:
        with open(LOG, "a") as f: f.write(line)
    except Exception: pass

def sh(cmd, timeout=8):
    """Run a shell command, return (rc, stdout)."""
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, text=True, timeout=timeout)
        return r.returncode, r.stdout, r.stderr
    except subprocess.TimeoutExpired:
        return 124, "", "timeout"
    except Exception as e:
        return 1, "", str(e)

# ─── data collectors ──────────────────────────────────────────────────────

def collect_system():
    out = {}
    # load + uptime
    _, up, _ = sh("uptime")
    out["uptime_line"] = up.strip()
    try:
        with open("/proc/loadavg") as f:
            la = f.read().split()
            out["load_1m"], out["load_5m"], out["load_15m"] = float(la[0]), float(la[1]), float(la[2])
    except Exception:
        pass
    # memory
    try:
        with open("/proc/meminfo") as f:
            mi = {}
            for line in f:
                k, _, v = line.partition(":")
                v = v.strip().split()
                if v: mi[k.strip()] = int(v[0])  # kB
        out["mem_total_kb"]     = mi.get("MemTotal", 0)
        out["mem_available_kb"] = mi.get("MemAvailable", 0)
        out["mem_used_kb"]      = mi.get("MemTotal", 0) - mi.get("MemAvailable", 0)
        out["mem_pct_used"]     = round(100 * (1 - mi.get("MemAvailable", 0) / max(mi.get("MemTotal", 1), 1)), 1)
        out["swap_total_kb"]    = mi.get("SwapTotal", 0)
        out["swap_free_kb"]     = mi.get("SwapFree", 0)
        out["swap_used_kb"]     = mi.get("SwapTotal", 0) - mi.get("SwapFree", 0)
        out["swap_pct_used"]    = round(100 * out["swap_used_kb"] / max(mi.get("SwapTotal", 1), 1), 1)
    except Exception:
        pass
    # disk on /
    _, df, _ = sh("df -BK --output=source,size,used,avail,pcent / | tail -1")
    df_parts = df.split()
    if len(df_parts) >= 5:
        out["disk_source"] = df_parts[0]
        out["disk_total_kb"] = int(df_parts[1].rstrip("K"))
        out["disk_used_kb"]  = int(df_parts[2].rstrip("K"))
        out["disk_avail_kb"] = int(df_parts[3].rstrip("K"))
        out["disk_pct_used"] = df_parts[4]
    out["hostname"] = os.uname().nodename
    out["ts"] = time.strftime("%Y-%m-%dT%H:%M:%S%z")
    return out

def collect_processes():
    out = {"by_cpu": [], "by_mem": []}
    for sort, key in [("-pcpu", "by_cpu"), ("-pmem", "by_mem")]:
        rc, p, _ = sh(f"ps -eo pid,user,pcpu,pmem,rss,etime,command --sort={sort} --no-headers | head -20")
        rows = []
        for line in p.strip().splitlines():
            parts = line.split(None, 6)
            if len(parts) < 7: continue
            rows.append({
                "pid": int(parts[0]),
                "user": parts[1],
                "cpu_pct": float(parts[2]),
                "mem_pct": float(parts[3]),
                "rss_kb": int(parts[4]),
                "etime": parts[5],
                "command": parts[6][:120],
            })
        out[key] = rows
    return out

def collect_docker():
    rc, p, _ = sh("docker ps -a --format '{{.Names}}|{{.Status}}|{{.Ports}}|{{.Image}}'", timeout=5)
    rows = []
    if rc == 0:
        for line in p.strip().splitlines():
            parts = line.split("|")
            if len(parts) >= 4:
                rows.append({"name": parts[0], "status": parts[1], "ports": parts[2], "image": parts[3]})
    return {"containers": rows}

def collect_sites():
    targets = ["hello", "nephew", "clinic", "git", "workflow"]
    out = []
    for sub in targets:
        url = f"https://{sub}.yousirjuan.ai/"
        rc, body, _ = sh(f"curl -s -o /dev/null -w '%{{http_code}}|%{{time_total}}' -m 5 {url}")
        if "|" in body:
            code, t = body.split("|")
            out.append({"sub": sub, "url": url, "http_code": code, "time_total_s": float(t)})
        else:
            out.append({"sub": sub, "url": url, "http_code": "000", "time_total_s": 5.0})
    return {"sites": out}

# ─── handler ──────────────────────────────────────────────────────────────

class H(http.server.BaseHTTPRequestHandler):
    def log_message(self, fmt, *args):
        slog("%s - %s" % (self.address_string(), fmt % args))

    def _send(self, code, body=b"", ctype="text/plain; charset=utf-8"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "GET,POST,OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type,Authorization")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        if body: self.wfile.write(body)

    def _json(self, code, data):
        self._send(code, json.dumps(data).encode(), "application/json; charset=utf-8")

    def _check_auth(self):
        if not TOKEN: return False, "no token configured"
        auth = self.headers.get("Authorization", "")
        if auth != f"Bearer {TOKEN}": return False, "unauthorized"
        return True, ""

    def do_OPTIONS(self):
        self._send(204)

    def do_GET(self):
        try:
            if self.path == "/health":
                self._send(200, b"ok\n")
            elif self.path == "/system":
                self._json(200, collect_system())
            elif self.path == "/processes":
                self._json(200, collect_processes())
            elif self.path == "/docker":
                self._json(200, collect_docker())
            elif self.path == "/sites":
                self._json(200, collect_sites())
            elif self.path == "/all":
                # convenience: single fetch for the DustPan panel
                self._json(200, {
                    "system": collect_system(),
                    "processes": collect_processes(),
                    "docker": collect_docker(),
                    "sites": collect_sites(),
                })
            else:
                self._send(404, b"not found\n")
        except Exception:
            slog("GET %s: %s" % (self.path, traceback.format_exc()))
            self._send(500, b"server error\n")

    def do_POST(self):
        try:
            ok, why = self._check_auth()
            if not ok:
                self._send(401, f"{why}\n".encode()); return
            n = int(self.headers.get("Content-Length", "0"))
            raw = self.rfile.read(n) if n > 0 else b"{}"
            try: body = json.loads(raw or b"{}")
            except json.JSONDecodeError:
                self._send(400, b"invalid json\n"); return

            if self.path == "/kill":
                pid = int(body.get("pid", 0))
                sig = body.get("signal", "TERM")
                if pid < 100:
                    self._send(400, b"refuse to kill PID < 100 (system)\n"); return
                rc, _, err = sh(f"kill -{sig} {pid}", timeout=3)
                slog(f"POST /kill pid={pid} sig={sig} rc={rc}")
                self._json(200 if rc == 0 else 500, {"pid": pid, "signal": sig, "rc": rc, "err": err.strip()})

            elif self.path == "/docker/stop":
                name = str(body.get("name", "")).strip()
                if not name or "/" in name or " " in name:
                    self._send(400, b"invalid container name\n"); return
                rc, _, err = sh(f"docker stop {name}", timeout=30)
                slog(f"POST /docker/stop name={name} rc={rc}")
                self._json(200 if rc == 0 else 500, {"name": name, "action": "stop", "rc": rc, "err": err.strip()})

            elif self.path == "/docker/start":
                name = str(body.get("name", "")).strip()
                if not name or "/" in name or " " in name:
                    self._send(400, b"invalid container name\n"); return
                rc, _, err = sh(f"docker start {name}", timeout=30)
                slog(f"POST /docker/start name={name} rc={rc}")
                self._json(200 if rc == 0 else 500, {"name": name, "action": "start", "rc": rc, "err": err.strip()})

            else:
                self._send(404, b"not found\n")
        except Exception:
            slog("POST %s: %s" % (self.path, traceback.format_exc()))
            self._send(500, b"server error\n")

class Server(http.server.ThreadingHTTPServer):
    daemon_threads = True

slog(f"starting on http://{BIND}:{PORT}")
Server((BIND, PORT), H).serve_forever()
PYEOF
