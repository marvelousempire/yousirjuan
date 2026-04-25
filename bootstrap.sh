#!/usr/bin/env bash
# bootstrap.sh — Universal entrypoint for the You-Sir Juan private AI stack.
#
# Detects the OS and dispatches to the right installer:
#   • macOS  → installers/macos.sh
#   • Linux  → installers/linux.sh   (Ubuntu/Debian — RHEL/Arch coming later)
#
# Usage:
#   git clone https://github.com/marvelousempire/yousirjuan.git
#   cd yousirjuan
#   bash bootstrap.sh
#
# Override the installer choice with FORCE_PLATFORM=macos|linux

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

step() { printf "\n\033[1;34m==>\033[0m \033[1m%s\033[0m\n" "$*"; }
note() { printf "    \033[2m%s\033[0m\n" "$*"; }
die()  { printf "\n\033[0;31m✗ %s\033[0m\n" "$*"; exit 1; }

step "You-Sir Juan — Private AI bootstrap"

PLATFORM="${FORCE_PLATFORM:-}"
if [[ -z "$PLATFORM" ]]; then
  case "$(uname -s)" in
    Darwin) PLATFORM="macos" ;;
    Linux)  PLATFORM="linux" ;;
    *)      die "Unsupported OS: $(uname -s). Set FORCE_PLATFORM=macos|linux to override." ;;
  esac
fi
note "Platform: $PLATFORM"

INSTALLER="$REPO_DIR/installers/$PLATFORM.sh"
[[ -f "$INSTALLER" ]] || die "Installer not found at $INSTALLER"

note "Dispatching to $INSTALLER"
exec bash "$INSTALLER" "$@"
