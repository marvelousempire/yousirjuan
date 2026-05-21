#!/usr/bin/env bash
# git-dual-push.sh — push to GitHub AND GitLab atomically with graceful
# degradation when one side is unreachable.
#
# Per Universal Rule 14 (Dual-Push to GitHub + GitLab) in
# rules/GLOBAL-RULES-FOR-USING-NEPHEW.md.
#
# Behavior:
#   1. Push to `origin` (GitHub) — must succeed; this is the public source.
#   2. Push to `gitlab` (git.yousirjuan.ai) — warn-but-continue if unreachable
#      (e.g. GitLab Docker container is stopped per the operator-intent file,
#      or network down, or project doesn't exist there yet).
#   3. When the gitlab push fails, record the pending sync in
#      ~/.local/share/yousirjuan/pushes-pending-to-gitlab.log
#      so `git-dual-push.sh --backfill` (or any script that scans the log)
#      can run them when GitLab returns.
#
# Usage:
#   bash tools/git-dual-push.sh                    # push current branch
#   bash tools/git-dual-push.sh feat/my-branch     # explicit branch
#   bash tools/git-dual-push.sh --tags             # push tags too
#   bash tools/git-dual-push.sh --backfill         # retry every line in pending log
#
# Rules:
#   - GitHub push fails → exit non-zero (this is the source-of-truth; don't
#     pretend success).
#   - GitLab push fails → warn + log + exit 0 (so the script chains nicely
#     in `&& blocks` and operator gets the GitHub push through).
#   - If neither remote is configured → die.

set -uo pipefail

PENDING_LOG="${HOME}/.local/share/yousirjuan/pushes-pending-to-gitlab.log"
mkdir -p "$(dirname "$PENDING_LOG")"
touch "$PENDING_LOG"

BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}✗ %s${NC}\n" "$*" >&2; exit 1; }

# ─── arg parsing ─────────────────────────────────────────────────────────────
PUSH_TAGS=""
BACKFILL=""
BRANCH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tags)     PUSH_TAGS="--tags"; shift;;
    --backfill) BACKFILL=1; shift;;
    --help|-h)
      head -30 "$0" | grep -E "^#" | sed 's/^# //;s/^#//'
      exit 0;;
    -*) die "unknown flag: $1";;
    *)  BRANCH="$1"; shift;;
  esac
done

cd "$(git rev-parse --show-toplevel 2>/dev/null)" || die "not in a git repo"
REPO_NAME=$(basename "$(pwd)")
BRANCH="${BRANCH:-$(git rev-parse --abbrev-ref HEAD)}"

# ─── backfill mode: retry pending entries ───────────────────────────────────
if [[ -n "$BACKFILL" ]]; then
  step "Backfilling pending GitLab pushes from $PENDING_LOG"
  if [[ ! -s "$PENDING_LOG" ]]; then
    ok "no pending entries"
    exit 0
  fi

  # Each line: <iso-timestamp>\t<repo-path>\t<branch>
  tmp=$(mktemp)
  while IFS=$'\t' read -r ts repo_path branch; do
    [[ -z "$repo_path" ]] && continue
    if [[ ! -d "$repo_path/.git" ]]; then
      warn "skip (no longer a repo): $repo_path"
      continue
    fi
    if (cd "$repo_path" && git push gitlab "$branch" 2>&1 | tail -3 | sed 's/^/  /'); then
      ok "backfilled: $repo_path $branch"
    else
      warn "still failing: $repo_path $branch — keeping in pending log"
      printf "%s\t%s\t%s\n" "$ts" "$repo_path" "$branch" >>"$tmp"
    fi
  done <"$PENDING_LOG"
  mv "$tmp" "$PENDING_LOG"
  ok "backfill done; remaining pending: $(wc -l <"$PENDING_LOG" | tr -d ' ')"
  exit 0
fi

# ─── regular dual-push ──────────────────────────────────────────────────────
HAS_ORIGIN=$(git remote get-url origin 2>/dev/null || echo "")
HAS_GITLAB=$(git remote get-url gitlab 2>/dev/null || echo "")

if [[ -z "$HAS_ORIGIN" && -z "$HAS_GITLAB" ]]; then
  die "neither 'origin' nor 'gitlab' remote configured in $REPO_NAME"
fi

step "Dual-push $REPO_NAME branch=$BRANCH"

# 1. GitHub (origin)
github_rc=0
if [[ -n "$HAS_ORIGIN" ]]; then
  if git push origin "$BRANCH" $PUSH_TAGS 2>&1 | tail -5 | sed 's/^/  /'; then
    ok "github: pushed $BRANCH"
  else
    github_rc=$?
    warn "github push returned non-zero (rc=$github_rc) — see lines above"
  fi
else
  warn "no 'origin' remote configured — skipping GitHub"
fi

# 2. GitLab — warn-but-continue if unreachable.
# `timeout` isn't on macOS by default. Try gtimeout (brew coreutils), then
# GNU timeout, then fall back to GIT_SSH_COMMAND with ConnectTimeout (SSH-level
# timeout — kicks in for connection failure but not mid-stream hangs; still
# better than a 7-min default).
gitlab_rc=0
if [[ -n "$HAS_GITLAB" ]]; then
  TIMEOUT_BIN=""
  for cmd in gtimeout timeout; do
    if command -v "$cmd" >/dev/null 2>&1; then TIMEOUT_BIN="$cmd 15"; break; fi
  done
  if [[ -n "$TIMEOUT_BIN" ]]; then
    push_cmd="$TIMEOUT_BIN git push gitlab $BRANCH $PUSH_TAGS"
  else
    push_cmd="env GIT_SSH_COMMAND='ssh -o ConnectTimeout=10 -o ServerAliveInterval=5 -o ServerAliveCountMax=2' git push gitlab $BRANCH $PUSH_TAGS"
  fi
  if eval "$push_cmd" 2>&1 | tail -5 | sed 's/^/  /'; then
    ok "gitlab: pushed $BRANCH"
  else
    gitlab_rc=$?
    warn "gitlab push failed (rc=$gitlab_rc) — likely GitLab container stopped"
    warn "  see /etc/yousirjuan/operator-intent.d/ on vps-godaddy for status"
    # Log for later backfill
    printf "%s\t%s\t%s\n" "$(date -Iseconds)" "$(pwd)" "$BRANCH" >>"$PENDING_LOG"
    warn "  recorded in $PENDING_LOG for backfill via --backfill"
  fi
else
  warn "no 'gitlab' remote configured — only pushed to GitHub"
  warn "  to add: git remote add gitlab ssh://git@72.167.151.251:2424/marvelousempire/$REPO_NAME.git"
fi

# Exit non-zero only if the GitHub push failed (the source-of-truth).
# GitLab failures are logged but don't fail the dual-push command.
exit $github_rc
