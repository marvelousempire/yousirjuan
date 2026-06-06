#!/usr/bin/env bash
# Install the repo's git hooks (Plan 0151, secret-hygiene rule).
# core.hooksPath is per-clone and NOT committed, so a fresh clone / another
# machine must run this once to activate the pre-commit + pre-push secret guards.
#
#   bash scripts/install-git-hooks.sh   (or: make hooks)
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

if [ ! -d .githooks ]; then
  echo "✗ .githooks/ not found — are you in the repo root?" >&2
  exit 1
fi

chmod +x .githooks/* 2>/dev/null || true
git config core.hooksPath .githooks
echo "✓ core.hooksPath = .githooks (pre-commit + pre-push secret guards active)"

if command -v gitleaks >/dev/null 2>&1; then
  echo "✓ gitleaks $(gitleaks version 2>/dev/null || echo present) — deep content scan enabled"
else
  echo "• gitleaks not installed — guards fall back to filename patterns only."
  echo "  Enable the deep scan:  brew install gitleaks   (macOS)  /  see github.com/gitleaks/gitleaks (Linux)"
fi
