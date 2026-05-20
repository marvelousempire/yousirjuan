# LEDGER-0010 — Sandbox CLI generator + dispatcher
#
# Usage:
#   make sandbox tool=<name>     # scaffold a new sandbox from _template/
#   make build   tool=<name>     # docker build the sandbox image
#   make run     tool=<name>     # drop into an interactive shell inside the sandbox
#   make stop    tool=<name>     # stop the running container (if any)
#   make rm      tool=<name>     # remove the image + workspace
#   make list                    # list all sandboxes and their state
#   make help                    # this message
#
# Each sandbox lives at its own subdirectory next to this Makefile.
# Each gets its own Docker network (sandbox-net-<tool>) and a scoped
# workspace mount at ~/sandbox-workspaces/<tool>/. Memory capped at 2g
# by default; override per-sandbox by editing the tool's docker-compose.yml.
#
# Per ADR-0001: containerize only the unruly (untrusted, native-deps hell,
# or memory-bounded). Don't migrate working native processes here.

SHELL := /bin/bash
SCRIPT_DIR := $(shell pwd)
WORKSPACE_BASE := $(HOME)/sandbox-workspaces

BLUE   := \033[1;34m
GREEN  := \033[1;32m
YELLOW := \033[1;33m
RED    := \033[1;31m
DIM    := \033[2m
NC     := \033[0m

.DEFAULT_GOAL := help

# ─────────────────────────────────────────────────────────────────────────────

.PHONY: help
help:
	@printf "${BLUE}Sandbox CLI generator${NC}\n"
	@printf "  ${GREEN}make sandbox${NC} tool=<name>   scaffold from _template/\n"
	@printf "  ${GREEN}make build${NC}   tool=<name>   docker build\n"
	@printf "  ${GREEN}make run${NC}     tool=<name>   interactive shell\n"
	@printf "  ${GREEN}make stop${NC}    tool=<name>   stop the running container\n"
	@printf "  ${GREEN}make rm${NC}      tool=<name>   remove image + workspace\n"
	@printf "  ${GREEN}make list${NC}                  list all sandboxes\n"
	@printf "\nExamples:\n"
	@printf "  ${DIM}make sandbox tool=grok-cli${NC}\n"
	@printf "  ${DIM}make build run tool=grok-cli${NC}\n"

# ─────────────────────────────────────────────────────────────────────────────

# Guard: required `tool=` argument
_require_tool:
	@if [ -z "$(tool)" ]; then \
		printf "${RED}error:${NC} tool=<name> required (e.g. ${DIM}make build tool=grok-cli${NC})\n"; \
		exit 1; \
	fi

# ─────────────────────────────────────────────────────────────────────────────

.PHONY: sandbox
sandbox: _require_tool
	@if [ -d "$(tool)" ]; then \
		printf "${YELLOW}warn:${NC} $(tool)/ already exists — not overwriting\n"; \
		exit 0; \
	fi
	@if [ ! -d "_template" ]; then \
		printf "${RED}error:${NC} _template/ missing — repo state corrupt?\n"; exit 1; \
	fi
	@printf "${BLUE}→${NC} scaffolding $(tool)/ from _template/\n"
	@cp -R _template "$(tool)"
	@for f in $(tool)/docker-compose.yml.tmpl $(tool)/Dockerfile.tmpl $(tool)/README.md.tmpl; do \
		dest="$${f%.tmpl}"; \
		sed -e "s|__TOOL__|$(tool)|g" "$$f" > "$$dest"; \
		rm "$$f"; \
	done
	@printf "${GREEN}✓${NC} scaffolded ledger/LEDGER-0010-sandbox-cli-generator/playbooks/$(tool)/\n"
	@printf "${DIM}  next: edit $(tool)/Dockerfile to install the tool, then 'make build tool=$(tool)'${NC}\n"

# ─────────────────────────────────────────────────────────────────────────────

.PHONY: build
build: _require_tool
	@if [ ! -d "$(tool)" ]; then \
		printf "${RED}error:${NC} $(tool)/ not scaffolded — run 'make sandbox tool=$(tool)' first\n"; exit 1; \
	fi
	@printf "${BLUE}→${NC} building sandbox-$(tool):latest\n"
	@mkdir -p "$(WORKSPACE_BASE)/$(tool)"
	@cd "$(tool)" && docker compose build
	@printf "${GREEN}✓${NC} built sandbox-$(tool):latest (workspace: $(WORKSPACE_BASE)/$(tool))\n"

.PHONY: run
run: _require_tool
	@printf "${BLUE}→${NC} running sandbox-$(tool) (interactive shell)\n"
	@cd "$(tool)" && docker compose run --rm sandbox

.PHONY: stop
stop: _require_tool
	@cd "$(tool)" && docker compose down --remove-orphans
	@printf "${GREEN}✓${NC} stopped sandbox-$(tool)\n"

.PHONY: rm
rm: _require_tool
	@printf "${YELLOW}!${NC} removing image sandbox-$(tool):latest and workspace $(WORKSPACE_BASE)/$(tool)\n"
	@docker rmi sandbox-$(tool):latest 2>/dev/null || true
	@printf "${DIM}  workspace dir NOT auto-deleted; run: rm -rf $(WORKSPACE_BASE)/$(tool)${NC}\n"

# ─────────────────────────────────────────────────────────────────────────────

.PHONY: list
list:
	@printf "${BLUE}Sandboxes${NC}\n"
	@for d in */ ; do \
		case "$$d" in _template/) continue ;; esac; \
		name="$${d%/}"; \
		state=$$(docker ps -a --filter "name=sandbox-$$name" --format "{{.Status}}" 2>/dev/null | head -1); \
		[ -z "$$state" ] && state="${DIM}(not started)${NC}"; \
		printf "  $(GREEN)%-20s$(NC) %s\n" "$$name" "$$state"; \
	done
	@printf "\n${DIM}workspaces base: $(WORKSPACE_BASE)${NC}\n"
