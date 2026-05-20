SHELL := /bin/bash

DEV_DIR        ?= $(HOME)/Developer
FS_MCP_SCOPE   ?= $(DEV_DIR)
VSCODE_APP     := /Applications/Visual Studio Code.app
CODE_CLI_SRC   := $(VSCODE_APP)/Contents/Resources/app/bin/code
CODE_CLI_DST   := /usr/local/bin/code
WORKSPACE_MCP  := $(DEV_DIR)/.vscode/mcp.json
CLINE_DIR      := $(HOME)/Library/Application Support/Code/User/globalStorage/saoudrizwan.claude-dev/settings
CLINE_MCP      := $(CLINE_DIR)/cline_mcp_settings.json
LAUNCH_PLIST   := $(HOME)/Library/LaunchAgents/com.ollama.server.plist
OLLAMA_LOG     := $(HOME)/Library/Logs/ollama.log

.PHONY: help install uninstall status start stop restart check-prereqs \
        code-cli cline-ext workspace-mcp cline-mcp ollama-agent

help:
	@echo "Targets:"
	@echo "  make install        - run all setup steps (idempotent)"
	@echo "  make uninstall      - remove everything this Makefile installs"
	@echo "  make status         - show current state of each piece"
	@echo "  make start          - load the Ollama LaunchAgent"
	@echo "  make stop           - unload the Ollama LaunchAgent"
	@echo "  make restart        - stop + start"
	@echo "  make check-prereqs  - verify VS Code, npx, ollama are present"
	@echo ""
	@echo "Variables (override on the command line):"
	@echo "  DEV_DIR=$(DEV_DIR)"
	@echo "  FS_MCP_SCOPE=$(FS_MCP_SCOPE)"

install: check-prereqs code-cli cline-ext workspace-mcp cline-mcp ollama-agent
	@echo ""
	@echo "✓ Setup complete. Open VS Code with:  code $(DEV_DIR)"

check-prereqs:
	@echo "→ Checking prerequisites"
	@test -d "$(VSCODE_APP)" || { echo "  ✗ VS Code not found at $(VSCODE_APP)"; exit 1; }
	@command -v npx  >/dev/null || { echo "  ✗ npx not on PATH (install Node.js)"; exit 1; }
	@command -v ollama >/dev/null || { echo "  ✗ ollama CLI not on PATH"; exit 1; }
	@echo "  ✓ VS Code, npx, ollama all present"

code-cli:
	@echo "→ Installing 'code' CLI shim at $(CODE_CLI_DST)"
	@if [ -L "$(CODE_CLI_DST)" ] || [ -e "$(CODE_CLI_DST)" ]; then \
		echo "  ✓ already exists, skipping"; \
	else \
		ln -s "$(CODE_CLI_SRC)" "$(CODE_CLI_DST)" && echo "  ✓ symlink created"; \
	fi

cline-ext: code-cli
	@echo "→ Installing Cline VS Code extension"
	@"$(CODE_CLI_DST)" --install-extension saoudrizwan.claude-dev 2>&1 | tail -1

workspace-mcp:
	@echo "→ Writing workspace MCP config: $(WORKSPACE_MCP)"
	@mkdir -p "$(dir $(WORKSPACE_MCP))"
	@printf '%s\n' \
'{' \
'  "servers": {' \
'    "filesystem": {' \
'      "command": "npx",' \
'      "args": [' \
'        "-y",' \
'        "@modelcontextprotocol/server-filesystem",' \
'        "$(FS_MCP_SCOPE)"' \
'      ]' \
'    },' \
'    "playwright": {' \
'      "command": "npx",' \
'      "args": [' \
'        "-y",' \
'        "@playwright/mcp@latest"' \
'      ]' \
'    }' \
'  }' \
'}' > "$(WORKSPACE_MCP)"
	@echo "  ✓ written"

cline-mcp:
	@echo "→ Writing Cline MCP config: $(CLINE_MCP)"
	@mkdir -p "$(CLINE_DIR)"
	@printf '%s\n' \
'{' \
'  "mcpServers": {' \
'    "filesystem": {' \
'      "command": "npx",' \
'      "args": [' \
'        "-y",' \
'        "@modelcontextprotocol/server-filesystem",' \
'        "$(FS_MCP_SCOPE)"' \
'      ],' \
'      "disabled": false,' \
'      "autoApprove": []' \
'    },' \
'    "playwright": {' \
'      "command": "npx",' \
'      "args": [' \
'        "-y",' \
'        "@playwright/mcp@latest"' \
'      ],' \
'      "disabled": false,' \
'      "autoApprove": []' \
'    }' \
'  }' \
'}' > "$(CLINE_MCP)"
	@echo "  ✓ written"

ollama-agent:
	@echo "→ Installing Ollama LaunchAgent: $(LAUNCH_PLIST)"
	@mkdir -p "$(dir $(LAUNCH_PLIST))" "$(dir $(OLLAMA_LOG))"
	@printf '%s\n' \
'<?xml version="1.0" encoding="UTF-8"?>' \
'<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">' \
'<plist version="1.0">' \
'<dict>' \
'    <key>Label</key><string>com.ollama.server</string>' \
'    <key>ProgramArguments</key>' \
'    <array>' \
'        <string>/usr/local/bin/ollama</string>' \
'        <string>serve</string>' \
'    </array>' \
'    <key>RunAtLoad</key><true/>' \
'    <key>KeepAlive</key><true/>' \
'    <key>StandardOutPath</key><string>$(OLLAMA_LOG)</string>' \
'    <key>StandardErrorPath</key><string>$(OLLAMA_LOG)</string>' \
'    <key>EnvironmentVariables</key>' \
'    <dict><key>PATH</key><string>/usr/local/bin:/usr/bin:/bin</string></dict>' \
'    <key>ProcessType</key><string>Background</string>' \
'</dict>' \
'</plist>' > "$(LAUNCH_PLIST)"
	@launchctl unload "$(LAUNCH_PLIST)" 2>/dev/null || true
	@launchctl load -w "$(LAUNCH_PLIST)"
	@sleep 2
	@if curl -s -m 3 http://localhost:11434/api/tags >/dev/null; then \
		echo "  ✓ Ollama responding on :11434"; \
	else \
		echo "  ✗ Ollama not responding — check $(OLLAMA_LOG)"; exit 1; \
	fi

start:
	@launchctl load -w "$(LAUNCH_PLIST)" 2>&1 && echo "✓ loaded"

stop:
	@launchctl unload "$(LAUNCH_PLIST)" 2>&1 && echo "✓ unloaded"

restart: stop start

status:
	@echo "── code CLI ─────────────────────────────"
	@if [ -L "$(CODE_CLI_DST)" ]; then echo "✓ $(CODE_CLI_DST) → $$(readlink $(CODE_CLI_DST))"; else echo "✗ missing"; fi
	@echo "── Cline extension ──────────────────────"
	@if command -v code >/dev/null && code --list-extensions 2>/dev/null | grep -q claude-dev; then echo "✓ installed"; else echo "✗ not installed"; fi
	@echo "── Workspace MCP config ─────────────────"
	@if [ -f "$(WORKSPACE_MCP)" ]; then echo "✓ $(WORKSPACE_MCP)"; else echo "✗ missing"; fi
	@echo "── Cline MCP config ─────────────────────"
	@if [ -f "$(CLINE_MCP)" ]; then echo "✓ $(CLINE_MCP)"; else echo "✗ missing"; fi
	@echo "── Ollama LaunchAgent ───────────────────"
	@if launchctl list | grep -q com.ollama.server; then \
		echo "✓ loaded: $$(launchctl list | grep com.ollama.server)"; \
	else \
		echo "✗ not loaded"; \
	fi
	@echo "── Ollama HTTP ──────────────────────────"
	@if curl -s -m 2 http://localhost:11434/api/tags >/dev/null; then \
		echo "✓ responding on :11434"; \
		curl -s http://localhost:11434/api/tags | python3 -c 'import sys,json;[print("  •",m["name"]) for m in json.load(sys.stdin)["models"]]' 2>/dev/null || true; \
	else \
		echo "✗ not responding"; \
	fi

uninstall:
	@echo "→ Unloading + removing LaunchAgent"
	@launchctl unload "$(LAUNCH_PLIST)" 2>/dev/null || true
	@rm -f "$(LAUNCH_PLIST)"
	@echo "→ Removing workspace MCP config"
	@rm -f "$(WORKSPACE_MCP)"
	@echo "→ Resetting Cline MCP config to empty"
	@if [ -f "$(CLINE_MCP)" ]; then echo '{ "mcpServers": {} }' > "$(CLINE_MCP)"; fi
	@echo "→ Removing 'code' CLI symlink"
	@if [ -L "$(CODE_CLI_DST)" ]; then rm -f "$(CODE_CLI_DST)"; fi
	@echo "  (Cline extension left installed — remove via VS Code if desired)"
	@echo "✓ uninstall complete"
