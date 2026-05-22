#!/usr/bin/env bash
# LEDGER-0024 — sync-and-drift.sh
# Runs every 5 min via systemd timer on the VPS.
# For each tracked marvelousempire repo, fetches both remotes and ensures
# gitlab/main == origin/main. Force-with-lease keeps concurrent pushes safe.
# Writes JSON drift report to /var/lib/yousirjuan/dual-push-drift-report.json.

set -u
shopt -s lastpipe

REPO_LIST="${REPO_LIST:-/opt/yousirjuan-sync/tracked-repos.txt}"
WORK_DIR="${WORK_DIR:-/var/cache/yousirjuan-sync}"
REPORT="${REPORT:-/var/lib/yousirjuan/dual-push-drift-report.json}"
LOG="${LOG:-/var/log/yousirjuan-sync.log}"
GITLAB_URL_BASE="ssh://git@127.0.0.1:2424/marvelousempire"
GITHUB_URL_BASE="git@github.com:marvelousempire"
PARALLEL="${PARALLEL:-5}"
TS="$(date -Iseconds)"

mkdir -p "$WORK_DIR" "$(dirname "$REPORT")" "$(dirname "$LOG")"
exec >>"$LOG" 2>&1
echo "=== $TS sync-and-drift run start ==="

sync_one() {
  local repo="$1"
  local d="$WORK_DIR/$repo"
  local result="ok"
  local origin_sha="" gitlab_sha="" action="none"

  if [ ! -d "$d/.git" ]; then
    git clone --bare --quiet "$GITHUB_URL_BASE/$repo.git" "$d" \
      || { echo "  ✗ clone failed: $repo"; result="clone-failed"; }
  fi

  if [ "$result" = "ok" ]; then
    cd "$d"
    git remote set-url origin "$GITHUB_URL_BASE/$repo.git"
    git remote get-url gitlab >/dev/null 2>&1 \
      || git remote add gitlab "$GITLAB_URL_BASE/$repo.git"

    git fetch --quiet origin '+refs/heads/main:refs/remotes/origin/main' 2>/dev/null \
      || { result="origin-fetch-failed"; }
    git fetch --quiet gitlab '+refs/heads/main:refs/remotes/gitlab/main' 2>/dev/null \
      || { result="gitlab-fetch-failed"; }

    if [ "$result" = "ok" ]; then
      origin_sha="$(git rev-parse origin/main 2>/dev/null || echo '?')"
      gitlab_sha="$(git rev-parse gitlab/main 2>/dev/null || echo '?')"
      if [ "$origin_sha" != "$gitlab_sha" ] && [ "$origin_sha" != "?" ]; then
        # Case 1: gitlab is a strict ancestor of origin → fast-forward push, no merge needed.
        if git merge-base --is-ancestor "$gitlab_sha" "$origin_sha" 2>/dev/null; then
          action="fast-forward-gitlab"
          if git push gitlab "origin/main:refs/heads/main" --quiet 2>/dev/null; then
            gitlab_sha="$origin_sha"
          else
            result="gitlab-ff-push-failed"
          fi
        # Case 2: gitlab has commits origin doesn't → create -s ours merge commit (plumbing
        # for bare repos: tree from origin, parents = both heads) and fast-forward both.
        else
          action="merge-ours-both-remotes"
          tree="$(git rev-parse "$origin_sha^{tree}" 2>/dev/null)"
          merge_sha="$(git commit-tree "$tree" -p "$origin_sha" -p "$gitlab_sha" -m "auto-sync(LEDGER-0024): reconcile origin/main + gitlab/main (no content change)" 2>/dev/null || echo '')"
          if [ -n "$merge_sha" ] && git push origin "$merge_sha:refs/heads/main" --quiet 2>/dev/null \
             && git push gitlab "$merge_sha:refs/heads/main" --quiet 2>/dev/null; then
            origin_sha="$merge_sha"
            gitlab_sha="$merge_sha"
          else
            result="merge-push-failed"
          fi
        fi
      fi
    fi
  fi

  # emit one JSONL line per repo (caller collects + wraps)
  printf '  {"repo":"%s","origin":"%s","gitlab":"%s","action":"%s","result":"%s"}\n' \
    "$repo" "$origin_sha" "$gitlab_sha" "$action" "$result"
}

# Run in batches of $PARALLEL using xargs to avoid hammering GitHub.
results_tmp="$(mktemp)"
trap 'rm -f "$results_tmp"' EXIT

export -f sync_one
export WORK_DIR GITLAB_URL_BASE GITHUB_URL_BASE
grep -v '^\s*#' "$REPO_LIST" | grep -v '^\s*$' | \
  xargs -n1 -P"$PARALLEL" -I{} bash -c 'sync_one "$@"' _ {} >>"$results_tmp"

drift_count="$(grep -cE '"action":"(fast-forward-gitlab|merge-ours-both-remotes)"' "$results_tmp" || echo 0)"
fail_count="$(grep -cE '"result":"(clone-failed|.*-fetch-failed|.*-push-failed)"' "$results_tmp" || echo 0)"
total="$(wc -l <"$results_tmp" | tr -d ' ')"

{
  echo '{'
  printf '  "ts": "%s",\n' "$TS"
  printf '  "total": %s,\n' "$total"
  printf '  "drift_corrected": %s,\n' "$drift_count"
  printf '  "failures": %s,\n' "$fail_count"
  echo  '  "entries": ['
  paste -sd, "$results_tmp" | sed 's/^/    /'
  echo  '  ]'
  echo '}'
} > "$REPORT.tmp" && mv "$REPORT.tmp" "$REPORT"

echo "=== $TS complete: total=$total drift=$drift_count fail=$fail_count ==="
