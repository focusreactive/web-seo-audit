#!/usr/bin/env bash
set -euo pipefail

# ─── Colors & Helpers ────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

info()    { printf "${BLUE}%s${RESET}\n" "$*"; }
success() { printf "${GREEN}%s${RESET}\n" "$*"; }
warn()    { printf "${YELLOW}%s${RESET}\n" "$*"; }

# ─── Header ──────────────────────────────────────────────────────────
printf "\n${BOLD}web-seo-audit${RESET} uninstaller\n\n"

# ─── Targets ─────────────────────────────────────────────────────────
SKILL_DIR="$HOME/.claude/skills/web-seo-audit"
AGENT_DIR="$HOME/.claude/agents"
REMOVED=0

# ─── Remove skill ────────────────────────────────────────────────────
if [[ -d "$SKILL_DIR" ]]; then
    info "Removing $SKILL_DIR ..."
    rm -rf "$SKILL_DIR"
    REMOVED=$((REMOVED + 1))
else
    warn "Skill directory not found: $SKILL_DIR (skipping)"
fi

# ─── Remove agents ───────────────────────────────────────────────────
for agent in web-seo-technical.md web-seo-performance.md web-seo-nextjs.md web-seo-aeo.md; do
    if [[ -f "$AGENT_DIR/$agent" ]]; then
        info "Removing $AGENT_DIR/$agent ..."
        rm "$AGENT_DIR/$agent"
        REMOVED=$((REMOVED + 1))
    else
        warn "Agent not found: $AGENT_DIR/$agent (skipping)"
    fi
done

# ─── Done ─────────────────────────────────────────────────────────────
printf "\n"
if [[ $REMOVED -gt 0 ]]; then
    success "Uninstalled successfully. All web-seo-audit files removed."
else
    warn "Nothing to remove — web-seo-audit was not installed."
fi
printf "\n"
