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

def _load_entities_config():
    """Load entity-map config (re-read each request so edits apply live)."""
    path = "/etc/yousirjuan/vps-agent-entities.json"
    try:
        with open(path, "r") as f:
            data = json.load(f)
        return data.get("entities", {})
    except (FileNotFoundError, json.JSONDecodeError):
        return {}

def _all_processes():
    """All processes with full command, RSS, CPU, MEM."""
    rc, p, _ = sh("ps -eo pid,user,pcpu,pmem,rss,etime,command --no-headers", timeout=10)
    rows = []
    for line in p.strip().splitlines():
        parts = line.split(None, 6)
        if len(parts) < 7: continue
        try:
            rows.append({
                "pid": int(parts[0]),
                "user": parts[1],
                "cpu_pct": float(parts[2]),
                "mem_pct": float(parts[3]),
                "rss_kb": int(parts[4]),
                "etime": parts[5],
                "command": parts[6],
            })
        except ValueError:
            continue
    return rows

def _match_entity(proc, containers_by_pid, entities_cfg):
    """Return (entity_key, entity_label, category) or None."""
    import re
    cmd = proc["command"]
    # 1. Container match — if this PID belongs to a container, attribute via container name
    container_name = containers_by_pid.get(proc["pid"])
    for ekey, e in entities_cfg.items():
        prefixes = e.get("container_prefixes", [])
        exact = e.get("container_exact", [])
        if container_name and (any(container_name.startswith(p) for p in prefixes) or container_name in exact):
            return ekey, e.get("label", ekey), e.get("category", "")
    # 2. systemd unit match — best-effort by /proc/<pid>/cgroup
    try:
        with open(f"/proc/{proc['pid']}/cgroup") as f:
            cg = f.read()
        for ekey, e in entities_cfg.items():
            for unit in e.get("systemd_units", []):
                if unit in cg:
                    return ekey, e.get("label", ekey), e.get("category", "")
    except (FileNotFoundError, PermissionError):
        pass
    # 3. Process command pattern match
    for ekey, e in entities_cfg.items():
        for pat in e.get("process_patterns", []):
            try:
                if re.search(pat, cmd):
                    return ekey, e.get("label", ekey), e.get("category", "")
            except re.error:
                continue
    return None

def _containers_by_pid():
    """Map: pid → container name. Uses `docker inspect` on each running container."""
    rc, p, _ = sh("docker ps -q", timeout=5)
    out = {}
    if rc != 0: return out
    for cid in p.strip().splitlines():
        if not cid: continue
        rc2, info, _ = sh(f"docker inspect --format '{{{{.Name}}}}|{{{{.State.Pid}}}}' {cid}", timeout=3)
        if "|" in info:
            name, pid_s = info.strip().split("|", 1)
            name = name.lstrip("/")
            try: out[int(pid_s)] = name
            except ValueError: continue
    # Also map child PIDs (a container's main PID has children we want attributed to it)
    if out:
        rc3, fam, _ = sh("ps -eo pid,ppid --no-headers", timeout=5)
        ppid_of = {}
        for line in fam.strip().splitlines():
            try:
                pid, ppid = line.split()
                ppid_of[int(pid)] = int(ppid)
            except ValueError: continue
        # Walk parents up to 5 hops for each pid to find a known container PID
        for pid in list(ppid_of.keys()):
            if pid in out: continue
            cur, hops = pid, 0
            while cur not in out and hops < 8:
                cur = ppid_of.get(cur)
                if cur is None or cur == 0: break
                hops += 1
            if cur in out:
                out[pid] = out[cur]
    return out

def collect_entities():
    """Group all processes + containers by entity. Aggregate CPU + RSS."""
    cfg = _load_entities_config()
    procs = _all_processes()
    cbp = _containers_by_pid()

    # Build container → entity lookup tables
    exact_to_entity = {}    # cname → (ekey, label, cat)
    prefix_to_entity = []   # list of (prefix, (ekey, label, cat))
    for ekey, e in cfg.items():
        tup = (ekey, e.get("label", ekey), e.get("category", ""))
        for name in e.get("container_exact", []):
            exact_to_entity[name] = tup
        for prefix in e.get("container_prefixes", []):
            prefix_to_entity.append((prefix, tup))

    rc, dock, _ = sh("docker ps -a --format '{{.Names}}|{{.Status}}|{{.Image}}'", timeout=5)
    containers = []
    if rc == 0:
        for line in dock.strip().splitlines():
            parts = line.split("|")
            if len(parts) < 3: continue
            cname = parts[0]
            match = exact_to_entity.get(cname)
            if not match:
                for pref, tup in prefix_to_entity:
                    if cname.startswith(pref):
                        match = tup; break
            ekey, label, cat = match if match else (None, None, None)
            containers.append({"name": cname, "status": parts[1], "image": parts[2],
                               "entity_key": ekey, "entity_label": label, "entity_category": cat})

    # Group processes
    buckets = {}
    unattributed_procs = []
    for proc in procs:
        match = _match_entity(proc, cbp, cfg)
        if match is None:
            unattributed_procs.append(proc)
            continue
        ekey, label, cat = match
        b = buckets.setdefault(ekey, {
            "key": ekey, "label": label, "category": cat,
            "cpu_pct_sum": 0.0, "mem_rss_kb_sum": 0, "mem_pct_sum": 0.0,
            "process_count": 0, "top_processes": [], "containers": [],
        })
        b["cpu_pct_sum"] += proc["cpu_pct"]
        b["mem_rss_kb_sum"] += proc["rss_kb"]
        b["mem_pct_sum"] += proc["mem_pct"]
        b["process_count"] += 1
        b["top_processes"].append(proc)

    # Attach containers (per entity)
    for c in containers:
        if c["entity_key"] and c["entity_key"] in buckets:
            buckets[c["entity_key"]]["containers"].append({"name": c["name"], "status": c["status"], "image": c["image"]})

    # Sort top_processes per bucket by mem_rss_kb (most to least); keep top 5
    for b in buckets.values():
        b["top_processes"].sort(key=lambda p: -p["rss_kb"])
        b["top_processes"] = b["top_processes"][:5]
        b["cpu_pct_sum"] = round(b["cpu_pct_sum"], 1)
        b["mem_pct_sum"] = round(b["mem_pct_sum"], 1)

    # Unattributed bucket
    unattributed_procs.sort(key=lambda p: -p["rss_kb"])
    unattributed = {
        "key": "_unattributed", "label": "Unattributed", "category": "other",
        "cpu_pct_sum": round(sum(p["cpu_pct"] for p in unattributed_procs), 1),
        "mem_rss_kb_sum": sum(p["rss_kb"] for p in unattributed_procs),
        "mem_pct_sum": round(sum(p["mem_pct"] for p in unattributed_procs), 1),
        "process_count": len(unattributed_procs),
        "top_processes": unattributed_procs[:5],
        "containers": [],
    }

    # Sort entities by mem_rss_kb_sum desc (heaviest first)
    entities = sorted(buckets.values(), key=lambda b: -b["mem_rss_kb_sum"])

    return {"entities": entities, "unattributed": unattributed, "ts": time.strftime("%Y-%m-%dT%H:%M:%S%z")}

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
            elif self.path == "/entities":
                self._json(200, collect_entities())
            elif self.path.startswith("/history"):
                # LEDGER-0015: serve last N lines of system-history.jsonl
                # Query: /history?lines=N  (default 200, max 2880 = 24h at 30s ticks)
                import urllib.parse as _up
                qs = _up.parse_qs(self.path.split("?", 1)[1] if "?" in self.path else "")
                try:
                    n = min(int(qs.get("lines", ["200"])[0]), 2880)
                except (ValueError, TypeError):
                    n = 200
                hist_path = "/var/lib/yousirjuan/system-history.jsonl"
                try:
                    with open(hist_path, "rb") as f:
                        data = f.read()
                    lines = data.splitlines()[-n:]
                    self._send(200, b"\n".join(lines) + b"\n", "application/x-ndjson; charset=utf-8")
                except FileNotFoundError:
                    self._send(404, b"history not yet populated (LEDGER-0015 server-tamer not installed?)\n")
            elif self.path == "/operator-intent":
                # LEDGER-0014: list intent files (filename + topic + first 12 lines body)
                import os as _os, glob as _glob
                intents = []
                for path in sorted(_glob.glob("/etc/yousirjuan/operator-intent.d/*.md")):
                    try:
                        with open(path) as f:
                            body = f.read()
                        intents.append({
                            "topic": _os.path.splitext(_os.path.basename(path))[0],
                            "path": path,
                            "mtime": _os.path.getmtime(path),
                            "preview": "\n".join(body.splitlines()[:12]),
                            "body": body,
                        })
                    except Exception as e:
                        intents.append({"topic": _os.path.basename(path), "error": str(e)})
                self._json(200, {"intents": intents})
            elif self.path == "/intent-drift":
                # LEDGER-0019: serve the drift report JSON written by intent-drift-check.sh
                report_path = "/var/lib/yousirjuan/intent-drift-report.json"
                try:
                    with open(report_path, "rb") as f:
                        self._send(200, f.read(), "application/json; charset=utf-8")
                except FileNotFoundError:
                    self._send(404, b'{"error":"drift report not yet generated (LEDGER-0019 timer not installed?)"}\n', "application/json")
            elif self.path == "/server-tamer":
                # LEDGER-0015: state file + last 30 log lines
                state_path = "/var/lib/yousirjuan/server-tamer-state.json"
                log_path = "/var/log/yousirjuan-server-tamer.log"
                state = {}
                try:
                    with open(state_path) as f:
                        state = json.load(f)
                except Exception:
                    pass
                log_tail = ""
                try:
                    with open(log_path, "rb") as f:
                        log_tail = b"\n".join(f.read().splitlines()[-30:]).decode("utf-8", errors="replace")
                except Exception:
                    pass
                self._json(200, {"state": state, "log_tail": log_tail})
            elif self.path == "/all":
                # convenience: single fetch for the DustPan panel
                self._json(200, {
                    "system": collect_system(),
                    "processes": collect_processes(),
                    "docker": collect_docker(),
                    "sites": collect_sites(),
                    "entities": collect_entities(),
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
