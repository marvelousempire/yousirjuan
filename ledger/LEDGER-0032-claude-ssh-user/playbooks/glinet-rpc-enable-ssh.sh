#!/usr/bin/env bash
# glinet-rpc-enable-ssh.sh — GL.iNet 4.x JSON-RPC: login + ensure dropbear enabled.
# Usage: GLINET_HOST=192.168.9.1 GLINET_PASSWORD='…' bash glinet-rpc-enable-ssh.sh
# (Slate on Flint WAN subnet — not 192.168.8.1 inner gateway)

set -euo pipefail

HOST="${GLINET_HOST:-192.168.9.1}"
USER="${GLINET_USER:-root}"
PASS="${GLINET_PASSWORD:-}"
RPC="https://${HOST}/rpc"

die() { printf '✗ %s\n' "$*" >&2; exit 1; }
[[ -n "$PASS" ]] || die "Set GLINET_PASSWORD"

command -v python3 >/dev/null || die "python3 required"

export GLINET_HOST="$HOST" GLINET_USER="$USER" GLINET_PASSWORD="$PASS" GLINET_RPC="$RPC"

python3 <<'PY'
import hashlib, json, os, sys
import urllib.request

host = os.environ["GLINET_HOST"]
user = os.environ["GLINET_USER"]
password = os.environ["GLINET_PASSWORD"]
rpc = os.environ["GLINET_RPC"]

def post(method, params):
    body = json.dumps({"jsonrpc": "2.0", "method": method, "params": params, "id": 1}).encode()
    req = urllib.request.Request(rpc, data=body, headers={"Content-Type": "application/json"}, method="POST")
    ctx = __import__("ssl").create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = __import__("ssl").CERT_NONE
    with urllib.request.urlopen(req, context=ctx, timeout=15) as r:
        return json.load(r)

try:
    from passlib.hash import sha256_crypt
except ImportError:
    import subprocess, tempfile
    venv = tempfile.mkdtemp(prefix="pyglinet-")
    subprocess.check_call([sys.executable, "-m", "venv", venv])
    subprocess.check_call([f"{venv}/bin/pip", "install", "-q", "passlib"])
    sys.path.insert(0, f"{venv}/lib/python3.*/site-packages".replace("3.*", f"{sys.version_info.major}.{sys.version_info.minor}"))
    from passlib.hash import sha256_crypt

ch = post("challenge", {"username": user})["result"]
alg = str(ch["alg"])
salt = ch["salt"]
nonce = ch["nonce"]
hm = ch.get("hash-method", "md5")

pw_hash = sha256_crypt.hash(password, salt=salt, rounds=5000) if alg == "5" else password
if hm == "sha256":
    login_hash = hashlib.sha256(f"{user}:{pw_hash}:{nonce}".encode()).hexdigest()
else:
    login_hash = hashlib.md5(f"{user}:{pw_hash}:{nonce}".encode()).hexdigest()

login = post("login", {"username": user, "hash": login_hash})
if login.get("error"):
    print("login error:", login["error"], file=sys.stderr)
    sys.exit(1)
sid = login["result"]["sid"]
print(f"OK login sid={sid[:8]}…")

def call(module, func, args=None):
    params = [sid, module, func]
    if args is not None:
        params.append(args)
    return post("call", params)

# Ensure dropbear enabled (idempotent)
for opt, val in [("enable", "1"), ("Port", "22"), ("PasswordAuth", "on")]:
    try:
        call("uci", "set", {"config": "dropbear", "section": "main", "option": opt, "values": val})
    except Exception:
        call("uci", "set", {"config": "dropbear", "section": "@dropbear[0]", "option": opt, "value": val})
call("uci", "commit", {"config": "dropbear"})
try:
    call("services", "restart", {"name": "dropbear"})
except Exception:
    pass
print("OK dropbear configured on", host)
PY
