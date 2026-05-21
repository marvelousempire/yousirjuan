#!/usr/bin/env bash
# 01-gitlab-memory-caps.sh — apply GitLab Puma + Sidekiq memory caps.
#
# Idempotent: re-running yields no diff and no errors.
# Reversible: invoke with --undo to restore from backup.
#
# Per LEDGER-0007 runbook 05:
#   - per_worker_max_memory_mb: default ~1024 → 400 (kills Puma worker if it grows past)
#   - sidekiq concurrency: default 20 → 10 (cuts in-flight job memory in half)
#
# Combined effect: ~1.2 GB of headroom on an 8 GB host under steady-state load.

set -euo pipefail

[[ $EUID -eq 0 ]] || { echo "must run as root (sudo)"; exit 1; }

# ─── Detect GitLab installation method ───────────────────────────────────────
# Original assumption: GitLab Omnibus (apt install gitlab-ce, /etc/gitlab/gitlab.rb).
# Real situation on the operator's VPS (per LEDGER-0005): GitLab CE in Docker,
# config via GITLAB_OMNIBUS_CONFIG env var on the container.

GITLAB_RB="/etc/gitlab/gitlab.rb"
BACKUP_DIR="/etc/gitlab/yousirjuan-backups"
MARKER="# LEDGER-0011 memory caps"
PUMA_LINE="puma['per_worker_max_memory_mb'] = 400  $MARKER"
SIDEKIQ_LINE="sidekiq['concurrency'] = 10  $MARKER"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

action="${1:-apply}"

# ─── Mode detection ──────────────────────────────────────────────────────────
# Returns one of: "omnibus" | "docker" | "none"
detect_mode() {
  if [[ -f "$GITLAB_RB" ]] && command -v gitlab-ctl >/dev/null 2>&1; then
    echo "omnibus"; return
  fi
  if command -v docker >/dev/null 2>&1 && docker ps -a --format '{{.Names}}' 2>/dev/null | grep -qx gitlab; then
    echo "docker"; return
  fi
  echo "none"
}

ensure_gitlab() {
  local mode; mode=$(detect_mode)
  if [[ "$mode" == "none" ]]; then
    warn "no GitLab Omnibus AND no 'gitlab' Docker container detected"
    warn "skipping memory caps (nothing to configure)"
    exit 0   # not an error — apply-all.sh should continue to step 2
  fi
}

backup_rb() {
  mkdir -p "$BACKUP_DIR"
  local stamp; stamp=$(date '+%Y-%m-%dT%H-%M-%S')
  cp "$GITLAB_RB" "$BACKUP_DIR/gitlab.rb.$stamp.bak"
  ok "backup: $BACKUP_DIR/gitlab.rb.$stamp.bak"
}

apply() {
  ensure_gitlab
  local mode; mode=$(detect_mode)
  if [[ "$mode" == "omnibus" ]]; then
    apply_omnibus
  elif [[ "$mode" == "docker" ]]; then
    apply_docker
  fi
}

apply_omnibus() {
  step "Applying LEDGER-0011 GitLab memory caps (Omnibus)"

  if grep -qF "$MARKER" "$GITLAB_RB"; then
    ok "marker already present — no changes (still safe to gitlab-ctl reconfigure)"
  else
    backup_rb
    {
      printf '\n# ─── LEDGER-0011 memory caps (begin) ──────────────────────\n'
      printf '%s\n' "$PUMA_LINE"
      printf '%s\n' "$SIDEKIQ_LINE"
      printf '# ─── LEDGER-0011 memory caps (end) ────────────────────────\n'
    } >> "$GITLAB_RB"
    ok "appended caps to $GITLAB_RB"
  fi

  step "Reconfiguring GitLab (takes ~60-90s)"
  gitlab-ctl reconfigure
  ok "GitLab reconfigured"

  step "Verifying caps in effect"
  grep -E "per_worker_max_memory_mb|sidekiq\['concurrency'\]" "$GITLAB_RB" | grep "$MARKER"
}

apply_docker() {
  step "Applying LEDGER-0011 GitLab memory caps (Docker container 'gitlab')"

  # GitLab CE Docker reads from the GITLAB_OMNIBUS_CONFIG env var.
  # We write the cap fragment to a host file the container mounts, OR
  # we set GITLAB_OMNIBUS_CONFIG on the container itself.
  #
  # The simplest, most portable path: write a custom rb fragment to
  # /etc/yousirjuan/gitlab-memory-caps.rb on the host, then ensure the
  # GitLab container mounts it at /etc/gitlab/gitlab.rb.d/yj-memory-caps.rb
  # on restart. GitLab loads any *.rb file under /etc/gitlab/gitlab.rb.d/
  # automatically on reconfigure.
  #
  # The operator must restart the gitlab container for the mount to apply
  # — we don't restart automatically because GitLab is currently stopped
  # per the operator's deliberate decision today.

  local FRAG_HOST="/etc/yousirjuan/gitlab-memory-caps.rb"
  mkdir -p "$(dirname "$FRAG_HOST")"

  cat > "$FRAG_HOST" <<'EOF'
# LEDGER-0011 memory caps — applied for the GitLab Docker container.
# Loaded automatically by gitlab-ctl reconfigure from /etc/gitlab/gitlab.rb.d/
# Trades GitLab throughput for ~1.2 GB headroom on an 8 GB host.
puma['per_worker_max_memory_mb'] = 400
sidekiq['concurrency'] = 10
EOF
  chmod 644 "$FRAG_HOST"
  ok "wrote $FRAG_HOST"

  # Check if the container is running. If so, we need to copy the file in
  # and reconfigure. If not, instruct the operator to add a mount when they
  # restart it.
  local container_state
  container_state=$(docker inspect --format '{{.State.Status}}' gitlab 2>/dev/null || echo "missing")

  if [[ "$container_state" == "running" ]]; then
    step "GitLab container is running — copying fragment in + reconfiguring"
    docker exec gitlab mkdir -p /etc/gitlab/gitlab.rb.d && \
    docker cp "$FRAG_HOST" "gitlab:/etc/gitlab/gitlab.rb.d/yj-memory-caps.rb"
    docker exec gitlab gitlab-ctl reconfigure 2>&1 | tail -10
    ok "GitLab Docker container reconfigured with memory caps"
  else
    warn "GitLab container is '$container_state' (not running)"
    warn "Fragment is staged at $FRAG_HOST"
    warn "When you restart the container, ensure it mounts:"
    warn "  -v $FRAG_HOST:/etc/gitlab/gitlab.rb.d/yj-memory-caps.rb:ro"
    warn "Or copy the file in once running:"
    warn "  docker cp $FRAG_HOST gitlab:/etc/gitlab/gitlab.rb.d/yj-memory-caps.rb && docker exec gitlab gitlab-ctl reconfigure"
  fi
}

undo() {
  ensure_gitlab
  local mode; mode=$(detect_mode)
  if [[ "$mode" == "docker" ]]; then
    step "Reverting LEDGER-0011 GitLab memory caps (Docker)"
    rm -f /etc/yousirjuan/gitlab-memory-caps.rb 2>/dev/null
    if [[ "$(docker inspect --format '{{.State.Status}}' gitlab 2>/dev/null)" == "running" ]]; then
      docker exec gitlab rm -f /etc/gitlab/gitlab.rb.d/yj-memory-caps.rb 2>/dev/null || true
      docker exec gitlab gitlab-ctl reconfigure 2>&1 | tail -5 || true
    fi
    ok "Docker caps reverted (file removed from host + container, reconfigure ran if running)"
    return 0
  fi

  step "Reverting LEDGER-0011 GitLab memory caps (Omnibus)"

  if ! grep -qF "$MARKER" "$GITLAB_RB"; then
    warn "marker not present — nothing to revert"
    return 0
  fi

  backup_rb

  # Remove our marked block.
  sed -i.tmp '/# ─── LEDGER-0011 memory caps (begin)/,/# ─── LEDGER-0011 memory caps (end)/d' "$GITLAB_RB"
  rm -f "${GITLAB_RB}.tmp"
  ok "removed marked block from $GITLAB_RB"

  step "Reconfiguring GitLab"
  gitlab-ctl reconfigure
  ok "GitLab reconfigured (back to defaults)"
}

case "$action" in
  apply|--apply|"")  apply ;;
  undo|--undo)       undo ;;
  *) die "usage: $0 [apply|undo]" ;;
esac
