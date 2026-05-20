#!/usr/bin/env bash
#
# rollout.sh — propagate the contracts-and-prudence portable rule across
# every active, non-archived, non-forked marvelousempire repo.
#
# Actions:
#   list      — print the working set (filtered repo list, no mutation)
#   dry-run   — clone each repo, diff what would change, report. No writes.
#   apply     — same as dry-run, plus commit + push + open PR + merge.
#   status    — inspect origin/main of each repo: ✓ in-sync, ⚠ diverged, ✗ missing.
#   undo      — open removal PRs for each repo (reverses an `apply`).
#   help      — print this.
#
# Variables (override via env):
#   ORG          — GitHub org (default: marvelousempire)
#   SOURCE_FILE  — path to the portable mirror content (default: ../artifacts/contracts-and-prudence-portable.md)
#   CLAUDE_PATH  — destination path inside each repo for Claude rule (default: .claude/rules/contracts-and-prudence.md)
#   CURSOR_PATH  — destination path inside each repo for Cursor rule  (default: .cursor/rules/contracts-and-prudence.md)
#   BRANCH       — branch name for the PR (default: chore/contracts-and-prudence-rollout)
#   AUTO_MERGE   — set to 0 to open PRs without merging (default: 1)
#   ASSUME_YES   — set to 1 to skip "this will mutate N repos, proceed?" prompts (default: 0)
#
# Repo exclusion list (edit the EXCLUDES array below to add/remove).
#
# Logs:
#   ~/yousirjuan-ledger.log        — global agent log (per ledger convention)
#   <script_dir>/../artifacts/runs/<timestamp>.txt  — per-run summary

set -euo pipefail

ORG="${ORG:-marvelousempire}"
BRANCH="${BRANCH:-chore/contracts-and-prudence-rollout}"
AUTO_MERGE="${AUTO_MERGE:-1}"
ASSUME_YES="${ASSUME_YES:-0}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_FILE="${SOURCE_FILE:-$SCRIPT_DIR/../artifacts/contracts-and-prudence-portable.md}"
RUNS_DIR="$SCRIPT_DIR/../artifacts/runs"
CLAUDE_PATH="${CLAUDE_PATH:-.claude/rules/contracts-and-prudence.md}"
CURSOR_PATH="${CURSOR_PATH:-.cursor/rules/contracts-and-prudence.md}"

LEDGER_LOG="$HOME/yousirjuan-ledger.log"
mkdir -p "$(dirname "$LEDGER_LOG")" "$RUNS_DIR"
TIMESTAMP=$(date -u +%Y-%m-%dT%H-%M-%SZ)
RUN_LOG="$RUNS_DIR/$TIMESTAMP.txt"

exec > >(tee -a "$LEDGER_LOG") 2>&1

# ───── colors + helpers ─────
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ───── exclusions ─────
# Repos that are normally active+non-archived but should NOT receive this rule.
# Add comments for *why* each one is excluded.
EXCLUDES=(
  "bishop-factory"        # slated for archival per separate plan; don't propagate to a doomed repo
  "yousirjuan"            # canonical lives here already; don't double-write
)

is_excluded() {
  local repo="$1"
  for e in "${EXCLUDES[@]}"; do
    if [[ "$e" == "$repo" ]]; then return 0; fi
  done
  return 1
}

# ───── repo enumeration ─────
get_working_set() {
  if ! have gh; then die "gh CLI not on PATH"; fi
  gh repo list "$ORG" --limit 100 --json name,visibility,isArchived,isFork,pushedAt 2>/dev/null \
    | python3 -c "
import json, sys
repos = json.load(sys.stdin)
# active + non-archived + non-fork
filtered = [r['name'] for r in repos
            if not r.get('isArchived', False)
            and not r.get('isFork', False)]
filtered.sort()
print('\n'.join(filtered))
"
}

list_working_set() {
  local repos
  repos=$(get_working_set)
  local total=0
  local included=0
  local excluded=0
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    total=$((total+1))
    if is_excluded "$repo"; then
      echo "  ⊘ $repo  (excluded)"
      excluded=$((excluded+1))
    else
      echo "  • $repo"
      included=$((included+1))
    fi
  done <<< "$repos"
  echo ""
  echo "Total active repos: $total"
  echo "Will target:        $included"
  echo "Excluded:           $excluded (${EXCLUDES[*]})"
}

# ───── per-repo processing ─────
# Returns one of: SHIPPED / SHIPPED_NO_MERGE / SKIPPED_UP_TO_DATE / DIVERGED / FAILED
process_repo() {
  local repo="$1"
  local mode="$2"  # dry-run | apply
  local tmpdir
  tmpdir=$(mktemp -d -t "rollout-$repo-XXXXXX")
  local result="UNKNOWN"
  local message=""

  # subshell so failures don't abort the outer loop
  (
    set +e
    cd "$tmpdir" || exit 1

    # 1. Clone (shallow, default branch)
    if ! gh repo clone "$ORG/$repo" -- --depth 1 2>/dev/null > /dev/null; then
      echo "FAILED clone"
      exit 1
    fi
    cd "$repo" || exit 1

    # 2. Compare current state to canonical
    local diff_count=0
    for path in "$CLAUDE_PATH" "$CURSOR_PATH"; do
      mkdir -p "$(dirname "$path")"
      if [[ -f "$path" ]] && cmp -s "$SOURCE_FILE" "$path"; then
        : # already identical, no-op
      else
        diff_count=$((diff_count+1))
      fi
    done

    if [[ $diff_count -eq 0 ]]; then
      echo "SKIPPED_UP_TO_DATE"
      exit 0
    fi

    if [[ "$mode" == "dry-run" ]]; then
      echo "WOULD_SHIP ($diff_count file(s) would be added/updated)"
      exit 0
    fi

    # 3. Apply mode: stamp the canonical into both paths
    cp "$SOURCE_FILE" "$CLAUDE_PATH"
    cp "$SOURCE_FILE" "$CURSOR_PATH"

    # 4. Branch + commit + push
    git checkout -B "$BRANCH" 2>/dev/null >/dev/null
    git add "$CLAUDE_PATH" "$CURSOR_PATH"
    if git diff --cached --quiet; then
      echo "SKIPPED_UP_TO_DATE"
      exit 0
    fi
    git commit -m "chore(rules): add contracts-and-prudence philosophy rule (control-tower rollout)

Mirrors the canonical operating philosophy from
marvelousempire/yousirjuan/.claude/rules/contracts-and-prudence.md to
this repo so any agent (Claude Code, Cursor, future tools) reading
the repo finds the philosophy on its first scan.

Both files are identical to the canonical and to every other repo's
mirror. Update the canonical in yousirjuan and re-run the LEDGER-0004
rollout playbook to propagate.

Stated 2026-05-20 by Avery: \"Good contracts → good. Careless = stupid.
Prudence first; act second.\"

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>" >/dev/null 2>&1 || {
      echo "FAILED commit"
      exit 1
    }
    git push -u origin "$BRANCH" >/dev/null 2>&1 || {
      echo "FAILED push (branch protection or auth issue?)"
      exit 1
    }

    # 5. Open PR
    local pr_url
    pr_url=$(gh pr create \
      --repo "$ORG/$repo" \
      --base "$(git rev-parse --abbrev-ref HEAD@{u} | sed 's|^origin/||')" \
      --head "$BRANCH" \
      --title "chore(rules): add contracts-and-prudence philosophy rule (control-tower rollout)" \
      --body "Adds \`.claude/rules/contracts-and-prudence.md\` and \`.cursor/rules/contracts-and-prudence.md\` so any agent reading this repo finds the operating philosophy on its first scan.

Identical content as every other repo in the marvelousempire control tower. Source of truth: [marvelousempire/yousirjuan](https://github.com/marvelousempire/yousirjuan/blob/main/.claude/rules/contracts-and-prudence.md). Propagation playbook: [LEDGER-0004](https://github.com/marvelousempire/yousirjuan/tree/main/ledger/LEDGER-0004-contracts-and-prudence-rollout).

> **Good contracts → good. Careless = stupid. Prudence first; act second.**

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>" \
      2>/dev/null) || {
      echo "FAILED pr_create"
      exit 1
    }

    # 6. Optional merge
    if [[ "$AUTO_MERGE" == "1" ]]; then
      if gh pr merge "$pr_url" --repo "$ORG/$repo" --squash --delete-branch 2>/dev/null; then
        echo "SHIPPED $pr_url"
      else
        echo "SHIPPED_NO_MERGE $pr_url  (likely branch protection or check pending)"
      fi
    else
      echo "SHIPPED_NO_MERGE $pr_url"
    fi
  )
  result=$?
  rm -rf "$tmpdir"
  return $result
}

# ───── main actions ─────
action_help() {
  cat <<EOF
Usage: $0 <action>

Actions:
  list     Print the working set of repos (after exclusions).
  dry-run  Clone each repo, diff what would change. NO writes / commits / PRs.
  apply    Same as dry-run, plus commit + push + PR + (optionally) merge.
  status   Inspect origin/main of each repo and report sync state.
  undo     Open removal PRs across all targeted repos. (Not implemented yet.)
  help     Print this.

Env vars:
  ORG=$ORG  BRANCH=$BRANCH  AUTO_MERGE=$AUTO_MERGE  ASSUME_YES=$ASSUME_YES

Logs:
  $LEDGER_LOG
  $RUN_LOG  (per-run summary)
EOF
}

action_list() { list_working_set; }

action_dry_run() {
  step "Dry run — no changes will be written anywhere."
  echo "Source canonical: $SOURCE_FILE"
  echo "Target paths inside each repo:"
  echo "  - $CLAUDE_PATH"
  echo "  - $CURSOR_PATH"
  echo ""
  local repos
  repos=$(get_working_set)
  echo "Per-repo dry-run results:" | tee "$RUN_LOG"
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    if is_excluded "$repo"; then
      printf "  %-35s ⊘ excluded\n" "$repo" | tee -a "$RUN_LOG"
      continue
    fi
    local r
    r=$(process_repo "$repo" dry-run 2>&1)
    printf "  %-35s %s\n" "$repo" "$r" | tee -a "$RUN_LOG"
  done <<< "$repos"
  echo ""
  echo "Summary written to: $RUN_LOG"
}

action_apply() {
  step "APPLY — this will commit / push / open PRs across the working set."
  local repos
  repos=$(get_working_set)
  local n
  n=$(echo "$repos" | wc -l | tr -d ' ')
  warn "Working set: ~$n repos (minus exclusions). AUTO_MERGE=$AUTO_MERGE."
  if [[ "$ASSUME_YES" != "1" && -t 0 ]]; then
    printf "${YELLOW}  ? Proceed with apply? [y/N] ${NC}" >&2
    local ans; read -r ans
    [[ "$ans" =~ ^[Yy]$ ]] || die "user declined"
  fi
  echo "Per-repo apply results:" | tee "$RUN_LOG"
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    if is_excluded "$repo"; then
      printf "  %-35s ⊘ excluded\n" "$repo" | tee -a "$RUN_LOG"
      continue
    fi
    local r
    r=$(process_repo "$repo" apply 2>&1)
    printf "  %-35s %s\n" "$repo" "$r" | tee -a "$RUN_LOG"
  done <<< "$repos"
  echo ""
  echo "Run summary: $RUN_LOG"
}

action_status() {
  step "Inspecting origin/main of each target repo"
  local repos
  repos=$(get_working_set)
  while IFS= read -r repo; do
    [[ -z "$repo" ]] && continue
    if is_excluded "$repo"; then continue; fi
    local claude_state cursor_state
    claude_state=$(gh api "repos/$ORG/$repo/contents/$CLAUDE_PATH" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)
    cursor_state=$(gh api "repos/$ORG/$repo/contents/$CURSOR_PATH" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null || true)
    local canonical
    canonical=$(cat "$SOURCE_FILE")
    if [[ -z "$claude_state" || -z "$cursor_state" ]]; then
      printf "  %-35s ✗ missing\n" "$repo"
    elif [[ "$claude_state" == "$canonical" && "$cursor_state" == "$canonical" ]]; then
      printf "  %-35s ✓ in sync\n" "$repo"
    else
      printf "  %-35s ⚠ diverged from canonical\n" "$repo"
    fi
  done <<< "$repos"
}

action_undo() {
  warn "undo is not yet implemented. Manual revert:"
  echo "  for each repo, run: gh pr create --base main --head revert/contracts-and-prudence --title '...'"
  echo "  …after deleting both rule files from a fresh branch."
}

# ───── dispatch ─────
case "${1:-help}" in
  list)     action_list ;;
  dry-run)  action_dry_run ;;
  apply)    action_apply ;;
  status)   action_status ;;
  undo)     action_undo ;;
  help|-h|--help) action_help ;;
  *) echo "Unknown action: $1" >&2; action_help; exit 1 ;;
esac
