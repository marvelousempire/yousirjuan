#!/usr/bin/env bash
# vendor/install-integrations.sh
#
# Install logic for the 3 community integrations vendored as submodules
# under vendor/. Source this file from installers/macos.sh and
# installers/linux.sh; each function is idempotent + safe to re-run.
#
# Used by:
#   installers/macos.sh   (after OpenClaw section)
#   installers/linux.sh   (after OpenClaw section)
#
# Required helpers (already defined in the calling installer): step, note, ok, warn, have
# Required env vars (already set in the calling installer): REPO_DIR, NPM_PREFIX

# ---- claude-mem ----
# Persistent memory for Claude Code. Adds hooks that capture context per
# session and inject relevant past context into future sessions.
# Repo: vendor/claude-mem
install_claude_mem() {
  step "claude-mem (persistent memory for Claude Code)"
  local DIR="$REPO_DIR/vendor/claude-mem"
  if [[ ! -d "$DIR" ]]; then
    warn "vendor/claude-mem not hydrated. Run: git submodule update --init --recursive"
    return 1
  fi

  ( cd "$DIR"
    note "npm install (in vendor dir, silent)..."
    npm install --silent --no-audit --no-fund 2>&1 | tail -3 || true
    if [[ -f package.json ]] && grep -q '"build"' package.json; then
      note "npm run build..."
      npm run build 2>&1 | tail -3 || true
    fi
    note "npm install -g . (publish CLI to $NPM_PREFIX)..."
    npm install -g . --silent --no-audit --no-fund 2>&1 | tail -3
  ) || { warn "claude-mem install failed — see output above"; return 1; }

  if have claude-mem; then
    note "Registering Claude Code hooks via claude-mem's installer..."
    claude-mem install 2>&1 | tail -5 || warn "claude-mem install (hook setup) failed; you can run it manually later"
    ok "claude-mem installed. HTTP API on :37777. Try: claude-mem status"
  else
    warn "claude-mem CLI not on PATH after install. Check: ls $NPM_PREFIX/bin/claude-mem"
    return 1
  fi
}

# ---- marketing-skills ----
# Markdown skills for AI agents. Symlink into ~/.claude/skills/ so Claude
# Code (and other Agent Skills-spec compatible tools) can find them.
install_marketing_skills() {
  step "marketing-skills (markdown skills for AI agents)"
  local DIR="$REPO_DIR/vendor/marketingskills"
  if [[ ! -d "$DIR/skills" ]]; then
    warn "vendor/marketingskills/skills not found. Run: git submodule update --init --recursive"
    return 1
  fi

  local CLAUDE_SKILLS="$HOME/.claude/skills"
  mkdir -p "$CLAUDE_SKILLS"

  local count=0
  for skill_dir in "$DIR/skills"/*/; do
    [[ -d "$skill_dir" ]] || continue
    local name; name="$(basename "$skill_dir")"
    # Prefix to avoid collision with operator's own skills + clearly mark vendor source
    ln -sfn "$skill_dir" "$CLAUDE_SKILLS/marketing-${name}"
    count=$((count + 1))
  done
  ok "Linked $count marketing skills into $CLAUDE_SKILLS/ (prefix: marketing-)"

  note "Open Claude Code; the new skills appear in /skills automatically"
  note "(To also import into Open WebUI Knowledge: see docs/extensions.md)"
}

# ---- ruflo ----
# Multi-agent orchestration via MCP. Installs the ruvflo CLI globally and
# runs its init command to bootstrap the local config.
install_ruflo() {
  step "ruflo (multi-agent orchestration)"
  local DIR="$REPO_DIR/vendor/ruflo"
  if [[ ! -d "$DIR" ]]; then
    warn "vendor/ruflo not hydrated. Run: git submodule update --init --recursive"
    return 1
  fi

  ( cd "$DIR"
    note "npm install (in vendor dir, silent — ruflo is large, takes a few min)..."
    npm install --silent --no-audit --no-fund 2>&1 | tail -5 || true
    if [[ -f package.json ]] && grep -q '"build"' package.json; then
      note "npm run build..."
      npm run build 2>&1 | tail -3 || true
    fi
    note "npm install -g . (publish ruvflo CLI to $NPM_PREFIX)..."
    npm install -g . --silent --no-audit --no-fund 2>&1 | tail -3
  ) || { warn "ruflo install failed — see output above"; return 1; }

  if have ruvflo; then
    ok "ruflo installed. CLI: ruvflo"
    note "Run: ruvflo init  (in any project dir to bootstrap multi-agent config)"
  elif have ruflo; then
    ok "ruflo installed. CLI: ruflo"
    note "Run: ruflo init  (in any project dir to bootstrap)"
  else
    warn "ruflo CLI not on PATH after install. Check: ls $NPM_PREFIX/bin/ | grep -E 'ru.?flo'"
    return 1
  fi
}

# ---- ai-skills-library ----
# Operator's curated catalog of AI skills, Claude/Cursor rules, marketing
# + design + project skills. Has its own link script that symlinks
# external skills into ~/.claude/skills and ~/.cursor/skills.
install_ai_skills_library() {
  step "ai-skills-library (curated AI skills catalog: skills + rules + Cursor/Claude bridges)"
  local DIR="$REPO_DIR/vendor/ai-skills-library"
  if [[ ! -d "$DIR" ]]; then
    warn "vendor/ai-skills-library not hydrated. Run: git submodule update --init --recursive"
    return 1
  fi
  if [[ ! -x "$DIR/scripts/link-external-skills-to-claude.sh" ]]; then
    warn "ai-skills-library: link script not found. Skipping."
    return 1
  fi

  note "Running ai-skills-library's own link-external-skills-to-claude.sh..."
  # Honor operator's env var; default to also linking to Cursor.
  LINK_EXTERNAL_TO_CURSOR="${LINK_EXTERNAL_TO_CURSOR:-1}" \
    bash "$DIR/scripts/link-external-skills-to-claude.sh" 2>&1 | sed 's/^/    /' | tail -20

  ok "ai-skills-library skills linked into ~/.claude/skills/ (and ~/.cursor/skills/ unless suppressed)"
  note "See $DIR/SKILL-INDEX.md for the full catalog"
}

# Convenience: dispatcher
install_all_selected_integrations() {
  local any=0
  if (( ${INSTALL_CLAUDE_MEM:-0} == 1 ));         then install_claude_mem         && any=1; fi
  if (( ${INSTALL_MARKETING_SKILLS:-0} == 1 ));   then install_marketing_skills   && any=1; fi
  if (( ${INSTALL_RUFLO:-0} == 1 ));              then install_ruflo              && any=1; fi
  if (( ${INSTALL_AI_SKILLS_LIBRARY:-0} == 1 ));  then install_ai_skills_library  && any=1; fi
  (( any == 0 )) && note "No vendor integrations selected"
  return 0
}
