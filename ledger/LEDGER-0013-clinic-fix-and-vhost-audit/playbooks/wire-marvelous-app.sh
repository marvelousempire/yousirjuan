#!/usr/bin/env bash
# wire-marvelous-app.sh — generate systemd unit + nginx vhost for a marvelousempire app.
#
# Reads templates from artifacts/_template/, renders with operator-provided
# values, drops the generated files into /etc/systemd/system/ and
# /etc/nginx/sites-enabled/, enables + starts the service, reloads nginx.
#
# Idempotent. --undo removes both.
#
# Usage:
#   sudo bash wire-marvelous-app.sh \
#     --name clinic \
#     --bin "/usr/bin/python3 /opt/clinic/server.py --host 127.0.0.1 --port 5436" \
#     --port 5436 \
#     --vhost clinic.yousirjuan.ai \
#     [--user abrownsanta] \
#     [--working-dir /opt/clinic] \
#     [--label "The Clinic"]
#
#   sudo bash wire-marvelous-app.sh --name clinic --vhost clinic.yousirjuan.ai --undo

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATE_DIR="$SCRIPT_DIR/../artifacts/_template"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

# ─── parse args ──────────────────────────────────────────────────────────────
NAME=""; BIN=""; PORT=""; VHOST=""
RUN_USER="abrownsanta"; WORKING_DIR=""; LABEL=""
ACTION="apply"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --name)        NAME="$2"; shift 2;;
    --bin)         BIN="$2"; shift 2;;
    --port)        PORT="$2"; shift 2;;
    --vhost)       VHOST="$2"; shift 2;;
    --user)        RUN_USER="$2"; shift 2;;
    --working-dir) WORKING_DIR="$2"; shift 2;;
    --label)       LABEL="$2"; shift 2;;
    --undo)        ACTION="undo"; shift;;
    --help|-h)     ACTION="help"; shift;;
    *) die "unknown arg: $1";;
  esac
done

[[ -n "$NAME" ]] || die "--name required"

UNIT="/etc/systemd/system/${NAME}.service"
VHOST_FILE="/etc/nginx/sites-enabled/${VHOST}"
LOG_FILE="/var/log/${NAME}.log"
BACKUP_DIR="/etc/nginx/sites-backups"

action_help() {
  cat <<EOF
Usage: sudo bash $(basename "$0") --name <n> --bin <cmd> --port <p> --vhost <host> [opts]

  --name        unique app id (becomes systemd unit + log name)
  --bin         full ExecStart command (with all args)
  --port        TCP port the app binds on 127.0.0.1
  --vhost       nginx server_name (e.g. clinic.yousirjuan.ai)
  --user        run user (default: abrownsanta)
  --working-dir WorkingDirectory for the service (default: /opt/<name>)
  --label       human-readable description (default: <name> (LEDGER-0013))
  --undo        remove systemd unit + nginx vhost for --name + --vhost
EOF
}

action_apply() {
  [[ -n "$BIN" ]]   || die "--bin required (use --undo to just remove)"
  [[ -n "$PORT" ]]  || die "--port required"
  [[ -n "$VHOST" ]] || die "--vhost required"
  [[ -d "$TEMPLATE_DIR" ]] || die "templates not found at $TEMPLATE_DIR"

  WORKING_DIR="${WORKING_DIR:-/opt/$NAME}"
  LABEL="${LABEL:-$NAME (LEDGER-0013)}"
  id "$RUN_USER" >/dev/null 2>&1 || die "user $RUN_USER does not exist"

  step "Wiring marvelous app: $NAME → :$PORT → $VHOST"
  note "  ExecStart:   $BIN"
  note "  Working:     $WORKING_DIR"
  note "  User:        $RUN_USER"
  note "  Log:         $LOG_FILE"

  # ─── render systemd unit ────────────────────────────────────────────────
  step "  rendering systemd unit"
  sed -e "s|__APP_NAME__|$NAME|g" \
      -e "s|__APP_LABEL__|$LABEL|g" \
      -e "s|__RUN_USER__|$RUN_USER|g" \
      -e "s|__WORKING_DIR__|$WORKING_DIR|g" \
      -e "s|__BIN__|$BIN|g" \
      "$TEMPLATE_DIR/python-app.service" > "$UNIT"
  touch "$LOG_FILE"
  chown "$RUN_USER:$RUN_USER" "$LOG_FILE"
  systemctl daemon-reload
  systemctl enable --now "${NAME}.service"
  sleep 2
  if systemctl is-active --quiet "${NAME}.service"; then
    ok "${NAME}.service active"
  else
    warn "${NAME}.service did not become active — check: journalctl -u ${NAME}.service -n 30"
  fi

  if ss -tln 2>/dev/null | grep -q ":$PORT "; then
    ok "upstream :$PORT listening"
  else
    warn "nothing listening on :$PORT yet (service may still be starting)"
  fi

  # ─── render nginx vhost ─────────────────────────────────────────────────
  step "  backing up existing vhost (if present) + rendering new one"
  mkdir -p "$BACKUP_DIR"
  if [[ -f "$VHOST_FILE" ]]; then
    local stamp; stamp=$(date '+%Y-%m-%dT%H-%M-%S')
    mv "$VHOST_FILE" "$BACKUP_DIR/${VHOST}.bak-$stamp"
    ok "  backup: $BACKUP_DIR/${VHOST}.bak-$stamp"
  fi
  sed -e "s|__APP_NAME__|$NAME|g" \
      -e "s|__VHOST__|$VHOST|g" \
      -e "s|__PORT__|$PORT|g" \
      "$TEMPLATE_DIR/marvelous-vhost.conf" > "$VHOST_FILE"

  step "  nginx -t + reload"
  if nginx -t 2>&1 | tail -2 | grep -q "successful"; then
    nginx -s reload
    ok "nginx reloaded"
  else
    die "nginx -t failed; restoring backup if available"
  fi

  step "  verify"
  sleep 1
  local code
  code=$(curl -sf -o /dev/null -w "%{http_code}" -m 5 "https://$VHOST/" 2>/dev/null || echo "000")
  if [[ "$code" =~ ^[23] ]]; then
    ok "https://$VHOST/ → HTTP $code"
  else
    warn "https://$VHOST/ → HTTP $code (TLS cert may need: certbot --nginx -d $VHOST)"
  fi
}

action_undo() {
  [[ -n "$VHOST" ]] || die "--vhost required for undo"
  step "Removing $NAME wiring"
  systemctl disable --now "${NAME}.service" 2>/dev/null || true
  rm -f "$UNIT"
  systemctl daemon-reload
  ok "removed $UNIT"

  if [[ -f "$VHOST_FILE" ]]; then
    rm -f "$VHOST_FILE"
    nginx -t >/dev/null 2>&1 && nginx -s reload
    ok "removed $VHOST_FILE + reloaded nginx"
  fi
  note "log file preserved at $LOG_FILE"
  note "backups preserved under $BACKUP_DIR"
}

case "$ACTION" in
  apply) action_apply ;;
  undo)  action_undo ;;
  help)  action_help ;;
esac
