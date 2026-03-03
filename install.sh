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
error()   { printf "${RED}%s${RESET}\n" "$*" >&2; }

# ─── Header ──────────────────────────────────────────────────────────
printf "\n${BOLD}web-seo-audit${RESET} installer\n"
printf "${DIM}Scan your web project for SEO issues. Get a scored report.${RESET}\n\n"

# ─── Detect source directory ─────────────────────────────────────────
# Works for both local clone and curl | bash (via temp clone)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [[ -f "$SCRIPT_DIR/skills/web-seo-audit/SKILL.md" ]]; then
    SOURCE_DIR="$SCRIPT_DIR"
else
    # Running via curl | bash — clone to temp dir
    info "Downloading web-seo-audit..."
    TEMP_DIR="$(mktemp -d)"
    trap 'rm -rf "$TEMP_DIR"' EXIT
    git clone --depth 1 https://github.com/focusreactive/web-seo-audit.git "$TEMP_DIR" 2>/dev/null \
        || { error "Failed to clone repository. Check your internet connection."; exit 1; }
    SOURCE_DIR="$TEMP_DIR"
    success "Downloaded."
fi

# ─── Verify source files exist ───────────────────────────────────────
for f in \
    "skills/web-seo-audit/SKILL.md" \
    "skills/web-seo-audit/references/quality-gates.md" \
    "skills/web-seo-audit/references/cwv-thresholds.md" \
    "skills/web-seo-audit/references/nextjs-patterns.md" \
    "skills/web-seo-audit/references/schema-types.md" \
    "skills/web-seo-audit/references/aeo-patterns.md" \
    "agents/web-seo-technical.md" \
    "agents/web-seo-performance.md" \
    "agents/web-seo-nextjs.md" \
    "agents/web-seo-aeo.md"; do
    if [[ ! -f "$SOURCE_DIR/$f" ]]; then
        error "Missing source file: $f"
        error "Are you running this from the web-seo-audit directory?"
        exit 1
    fi
done

# ─── Install targets ─────────────────────────────────────────────────
SKILL_DIR="$HOME/.claude/skills/web-seo-audit"
AGENT_DIR="$HOME/.claude/agents"

# ─── Install skill + references ──────────────────────────────────────
info "Installing skill to $SKILL_DIR ..."
mkdir -p "$SKILL_DIR/references"
cp "$SOURCE_DIR/skills/web-seo-audit/SKILL.md"                     "$SKILL_DIR/SKILL.md"
cp "$SOURCE_DIR/skills/web-seo-audit/references/quality-gates.md"   "$SKILL_DIR/references/quality-gates.md"
cp "$SOURCE_DIR/skills/web-seo-audit/references/cwv-thresholds.md"  "$SKILL_DIR/references/cwv-thresholds.md"
cp "$SOURCE_DIR/skills/web-seo-audit/references/nextjs-patterns.md" "$SKILL_DIR/references/nextjs-patterns.md"
cp "$SOURCE_DIR/skills/web-seo-audit/references/schema-types.md"    "$SKILL_DIR/references/schema-types.md"
cp "$SOURCE_DIR/skills/web-seo-audit/references/aeo-patterns.md"   "$SKILL_DIR/references/aeo-patterns.md"

# ─── Install agents ──────────────────────────────────────────────────
info "Installing agents to $AGENT_DIR ..."
mkdir -p "$AGENT_DIR"
cp "$SOURCE_DIR/agents/web-seo-technical.md"   "$AGENT_DIR/web-seo-technical.md"
cp "$SOURCE_DIR/agents/web-seo-performance.md" "$AGENT_DIR/web-seo-performance.md"
cp "$SOURCE_DIR/agents/web-seo-nextjs.md"      "$AGENT_DIR/web-seo-nextjs.md"
cp "$SOURCE_DIR/agents/web-seo-aeo.md"        "$AGENT_DIR/web-seo-aeo.md"

# ─── Verify installation ─────────────────────────────────────────────
info "Verifying installation..."
VERIFY_FAILED=0
for f in \
    "$SKILL_DIR/SKILL.md" \
    "$SKILL_DIR/references/quality-gates.md" \
    "$SKILL_DIR/references/cwv-thresholds.md" \
    "$SKILL_DIR/references/nextjs-patterns.md" \
    "$SKILL_DIR/references/schema-types.md" \
    "$SKILL_DIR/references/aeo-patterns.md" \
    "$AGENT_DIR/web-seo-technical.md" \
    "$AGENT_DIR/web-seo-performance.md" \
    "$AGENT_DIR/web-seo-nextjs.md" \
    "$AGENT_DIR/web-seo-aeo.md"; do
    if [[ ! -r "$f" ]]; then
        error "Verification failed: $f is missing or not readable"
        VERIFY_FAILED=1
    fi
done

if [[ $VERIFY_FAILED -eq 1 ]]; then
    error "Installation verification failed. Some files may not have been copied correctly."
    error "Try running the installer again, or install manually."
    exit 1
fi

# ─── Done ─────────────────────────────────────────────────────────────
printf "\n"
success "Installed and verified successfully!"
printf "\n"
printf "  ${BOLD}Installed files:${RESET}\n"
printf "  ${DIM}Skill${RESET}   %s/SKILL.md\n" "$SKILL_DIR"
printf "  ${DIM}Refs${RESET}    %s/references/ (5 files)\n" "$SKILL_DIR"
printf "  ${DIM}Agents${RESET}  %s/web-seo-*.md (4 files)\n" "$AGENT_DIR"
printf "\n"
printf "  ${BOLD}Usage:${RESET}\n"
printf "    Open Claude Code in any web project and run:\n"
printf "\n"
printf "    ${GREEN}/web-seo-audit${RESET}             Full audit with scored report\n"
printf "    ${GREEN}/web-seo-audit nextjs${RESET}      Next.js-specific deep check\n"
printf "    ${GREEN}/web-seo-audit cwv${RESET}         Core Web Vitals focus\n"
printf "    ${GREEN}/web-seo-audit meta${RESET}        Meta tags & structured data\n"
printf "    ${GREEN}/web-seo-audit images${RESET}      Image optimization check\n"
printf "    ${GREEN}/web-seo-audit aeo${RESET}         AI search readiness check\n"
printf "    ${GREEN}/web-seo-audit page <path>${RESET}  Single page analysis\n"
printf "\n"
printf "  To uninstall: ${DIM}./uninstall.sh${RESET} or ${DIM}curl -fsSL https://raw.githubusercontent.com/focusreactive/web-seo-audit/main/uninstall.sh | bash${RESET}\n"
printf "\n"
