#!/usr/bin/env bash
#
# install.sh — shell sibling of the Makefile in this same folder.
#
# Usage:
#   ./install.sh             # print help
#   ./install.sh install     # run all setup steps (idempotent)
#   ./install.sh uninstall   # remove everything this script installs
#   ./install.sh status      # show current state of each piece
#   ./install.sh start       # load the Ollama LaunchAgent
#   ./install.sh stop        # unload the Ollama LaunchAgent
#   ./install.sh restart     # stop + start
#   ./install.sh check-prereqs
#
# Variables (override via env):
#   DEV_DIR        — workspace root (default: $HOME/Developer)
#   FS_MCP_SCOPE   — path the filesystem MCP server may touch (default: $DEV_DIR)
#
# This script reproduces the same state as the Makefile in this folder.
# Either tool works; both are idempotent. Prefer make on machines that have it;
# this script is the fallback for environments that don't.

set -euo pipefail

# ───── config (override via env) ─────
DEV_DIR="${DEV_DIR:-$HOME/Developer}"
FS_MCP_SCOPE="${FS_MCP_SCOPE:-$DEV_DIR}"
VSCODE_APP="/Applications/Visual Studio Code.app"
CODE_CLI_SRC="$VSCODE_APP/Contents/Resources/app/bin/code"
CODE_CLI_DST="/usr/local/bin/code"
WORKSPACE_MCP="$DEV_DIR/.vscode/mcp.json"
CLINE_DIR="$HOME/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings"
CLINE_MCP="$CLINE_DIR/cline_mcp_settings.json"
LAUNCH_PLIST="$HOME/Library/LaunchAgents/com.ollama.server.plist"
OLLAMA_LOG="$HOME/Library/Logs/ollama.log"
LEDGER_LOG="$HOME/yousirjuan-ledger.log"

mkdir -p "$(dirname "$LEDGER_LOG")"
exec > >(tee -a "$LEDGER_LOG") 2>&1

# ───── colors + helpers (canonical yousirjuan set) ─────
BLUE='\033[1;34m'; GREEN='\033[1;32m'; YELLOW='\033[1;33m'; RED='\033[1;31m'; DIM='\033[2m'; NC='\033[0m'
step() { printf "${BLUE}→ %s${NC}\n" "$*"; }
note() { printf "${DIM}  %s${NC}\n" "$*"; }
ok()   { printf "${GREEN}  ✓ %s${NC}\n" "$*"; }
warn() { printf "${YELLOW}  ⚠ %s${NC}\n" "$*"; }
die()  { printf "${RED}  ✗ %s${NC}\n" "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

# ───── actions ─────

action_help() {
  cat <<EOF
Usage: $0 <action>

Actions:
  install        run all setup steps (idempotent)
  uninstall      remove everything this script installs
  status         show current state of each piece
  start          load the Ollama LaunchAgent
  stop           unload the Ollama LaunchAgent
  restart        stop + start
  check-prereqs  verify VS Code, npx, ollama are present

Variables (override via env):
  DEV_DIR=$DEV_DIR
  FS_MCP_SCOPE=$FS_MCP_SCOPE

Logs: $LEDGER_LOG
EOF
}

action_check_prereqs() {
  step "Checking prerequisites"
  [[ -d "$VSCODE_APP" ]] || die "VS Code not found at $VSCODE_APP"
  have npx                || die "npx not on PATH (install Node.js)"
  have ollama             || die "ollama CLI not on PATH"
  ok "VS Code, npx, ollama all present"
}

action_code_cli() {
  step "Installing 'code' CLI shim at $CODE_CLI_DST"
  if [[ -L "$CODE_CLI_DST" || -e "$CODE_CLI_DST" ]]; then
    ok "already exists, skipping"
  else
    ln -s "$CODE_CLI_SRC" "$CODE_CLI_DST"
    ok "symlink created"
  fi
}

action_cline_ext() {
  step "Installing Cline VS Code extension"
  "$CODE_CLI_DST" --install-extension saoudrizwan.claude-dev 2>&1 | tail -1
}

action_workspace_mcp() {
  step "Writing workspace MCP config: $WORKSPACE_MCP"
  mkdir -p "$(dirname "$WORKSPACE_MCP")"
  cat > "$WORKSPACE_MCP" <<EOF
{
  "servers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "$FS_MCP_SCOPE"
      ]
    },
    "playwright": {
      "command": "npx",
      "args": [
        "-y",
        "@playwright/mcp@latest"
      ]
    }
  }
}
EOF
  ok "written"
}

action_cline_mcp() {
  step "Writing Cline MCP config: $CLINE_MCP"
  mkdir -p "$CLINE_DIR"
  cat > "$CLINE_MCP" <<EOF
{
  "mcpServers": {
    "filesystem": {
      "command": "npx",
      "args": [
        "-y",
        "@modelcontextprotocol/server-filesystem",
        "$FS_MCP_SCOPE"
      ],
      "disabled": false,
      "autoApprove": []
    },
    "playwright": {
      "command": "npx",
      "args": [
        "-y",
        "@playwright/mcp@latest"
      ],
      "disabled": false,
      "autoApprove": []
    }
  }
}
EOF
  ok "written"
}

action_ollama_agent() {
  step "Installing Ollama LaunchAgent: $LAUNCH_PLIST"
  mkdir -p "$(dirname "$LAUNCH_PLIST")" "$(dirname "$OLLAMA_LOG")"
  cat > "$LAUNCH_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key><string>com.ollama.server</string>
    <key>ProgramArguments</key>
    <array>
        <string>/usr/local/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>RunAtLoad</key><true/>
    <key>KeepAlive</key><true/>
    <key>StandardOutPath</key><string>$OLLAMA_LOG</string>
    <key>StandardErrorPath</key><string>$OLLAMA_LOG</string>
    <key>EnvironmentVariables</key>
    <dict><key>PATH</key><string>/usr/local/bin:/usr/bin:/bin</string></dict>
    <key>ProcessType</key><string>Background</string>
</dict>
</plist>
EOF
  launchctl unload "$LAUNCH_PLIST" 2>/dev/null || true
  launchctl load -w "$LAUNCH_PLIST"
  sleep 2
  if curl -s -m 3 http://localhost:11434/api/tags >/dev/null; then
    ok "Ollama responding on :11434"
  else
    die "Ollama not responding — check $OLLAMA_LOG"
  fi
}

action_install() {
  action_check_prereqs
  action_code_cli
  action_cline_ext
  action_workspace_mcp
  action_cline_mcp
  action_ollama_agent
  echo
  ok "Setup complete. Open VS Code with:  code $DEV_DIR"
}

action_start() {
  launchctl load -w "$LAUNCH_PLIST" 2>&1
  ok "loaded"
}

action_stop() {
  launchctl unload "$LAUNCH_PLIST" 2>&1
  ok "unloaded"
}

action_restart() {
  action_stop || true
  action_start
}

action_status() {
  echo "── code CLI ─────────────────────────────"
  if [[ -L "$CODE_CLI_DST" ]]; then
    echo "✓ $CODE_CLI_DST → $(readlink "$CODE_CLI_DST")"
  else
    echo "✗ missing"
  fi
  echo "── Cline extension ──────────────────────"
  if have code && code --list-extensions 2>/dev/null | grep -q claude-dev; then
    echo "✓ installed"
  else
    echo "✗ not installed"
  fi
  echo "── Workspace MCP config ─────────────────"
  [[ -f "$WORKSPACE_MCP" ]] && echo "✓ $WORKSPACE_MCP" || echo "✗ missing"
  echo "── Cline MCP config ─────────────────────"
  [[ -f "$CLINE_MCP" ]] && echo "✓ $CLINE_MCP" || echo "✗ missing"
  echo "── Ollama LaunchAgent ───────────────────"
  if launchctl list | grep -q com.ollama.server; then
    echo "✓ loaded: $(launchctl list | grep com.ollama.server)"
  else
    echo "✗ not loaded"
  fi
  echo "── Ollama HTTP ──────────────────────────"
  if curl -s -m 2 http://localhost:11434/api/tags >/dev/null; then
    echo "✓ responding on :11434"
    curl -s http://localhost:11434/api/tags 2>/dev/null | python3 -c 'import sys,json;[print("  •",m["name"]) for m in json.load(sys.stdin)["models"]]' 2>/dev/null || true
  else
    echo "✗ not responding"
  fi
}

action_uninstall() {
  step "Unloading + removing LaunchAgent"
  launchctl unload "$LAUNCH_PLIST" 2>/dev/null || true
  rm -f "$LAUNCH_PLIST"
  step "Removing workspace MCP config"
  rm -f "$WORKSPACE_MCP"
  step "Resetting Cline MCP config to empty"
  [[ -f "$CLINE_MCP" ]] && echo '{ "mcpServers": {} }' > "$CLINE_MCP" || true
  step "Removing 'code' CLI symlink"
  [[ -L "$CODE_CLI_DST" ]] && rm -f "$CODE_CLI_DST" || true
  note "(Cline extension left installed — remove via VS Code if desired)"
  ok "uninstall complete"
}

# ───── dispatcher ─────
case "${1:-help}" in
  install)        action_install ;;
  uninstall)      action_uninstall ;;
  status)         action_status ;;
  start)          action_start ;;
  stop)           action_stop ;;
  restart)        action_restart ;;
  check-prereqs)  action_check_prereqs ;;
  code-cli)       action_code_cli ;;
  cline-ext)      action_cline_ext ;;
  workspace-mcp)  action_workspace_mcp ;;
  cline-mcp)      action_cline_mcp ;;
  ollama-agent)   action_ollama_agent ;;
  help|-h|--help) action_help ;;
  *)              echo "Unknown action: $1" >&2; action_help; exit 1 ;;
esac
