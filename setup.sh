#!/usr/bin/env bash
set -euo pipefail

# Require bash 4+ for full feature support.
# macOS ships bash 3.2 — install a modern bash via Homebrew:
#   brew install bash
if (( BASH_VERSINFO[0] < 4 )); then
  echo ""
  echo "⚠  bash 4+ is recommended. You are running bash $BASH_VERSION."
  echo "   On macOS: brew install bash"
  echo "   Continuing anyway (bash 3.2 compatible mode)..."
  echo ""
fi

# ─────────────────────────────────────────────
#  project-bootstrap / setup.sh
#  Interactively configure a new project and
#  generate a self-contained init.sh ready to commit.
# ─────────────────────────────────────────────

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB="$SCRIPT_DIR/lib"

# Guard: ensure lib directory is present (catches partial clones / missing files)
if [[ ! -d "$LIB" ]]; then
  echo ""
  echo "✖ Cannot find the lib/ directory at: $LIB"
  echo ""
  echo "  This usually means you only downloaded setup.sh rather than cloning"
  echo "  the full repository. Please run:"
  echo ""
  echo "    git clone https://github.com/your-org/project-bootstrap.git"
  echo "    cd project-bootstrap"
  echo "    chmod +x setup.sh && ./setup.sh"
  echo ""
  exit 1
fi

# Verify each lib file exists before sourcing
for lib_file in colours.sh checks.sh claude_api.sh prompts.sh aider_config.sh git_setup.sh; do
  if [[ ! -f "$LIB/$lib_file" ]]; then
    echo "✖ Missing lib file: lib/$lib_file — please re-clone the repository."
    exit 1
  fi
done

source "$LIB/colours.sh"
source "$LIB/checks.sh"
source "$LIB/claude_api.sh"
source "$LIB/prompts.sh"
source "$LIB/aider_config.sh"
source "$LIB/git_setup.sh"
source "$LIB/generators/generate_init.sh"

# ── Banner ────────────────────────────────────
clear
echo ""
echo -e "${CYAN}╔══════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║       🚀  project-bootstrap  🚀          ║${NC}"
echo -e "${CYAN}║   Bootstrap any project in minutes       ║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════╝${NC}"
echo ""

# ── Step 1: Dependency checks ─────────────────
step "Checking dependencies..."
check_dependencies

# ── Step 2: Claude API key ────────────────────
step "Claude API key"
prompt_claude_api_key

# ── Step 3: Project synopsis ──────────────────
step "Project synopsis"
echo -e "${YELLOW}Describe what you want to build. Be as detailed as you like.${NC}"
echo -e "${DIM}(Type your synopsis. Press Ctrl+D on a new line when done)${NC}"
echo ""
PROJECT_SYNOPSIS=$(cat)
echo ""
info "Got it. Asking Claude to suggest your stack..."

# ── Step 4: Claude suggests the stack ─────────
SUGGESTIONS=$(claude_suggest_stack "$PROJECT_SYNOPSIS" "$ANTHROPIC_API_KEY")
parse_suggestions "$SUGGESTIONS"

# ── Step 5: Review / override suggestions ─────
step "Review stack suggestions"
review_suggestions

# ── Step 6: Configure aider ───────────────────
step "Configure aider"
configure_aider

# ── Step 7: Git init ──────────────────────────
step "Initialise git"
setup_git

# ── Step 8: Generate init.sh ──────────────────
step "Generating init.sh..."
generate_init_sh

echo ""
echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║   ✅  Setup complete!                    ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
echo ""
echo -e "Next steps:"
echo -e "  ${CYAN}1.${NC} Review and run ${BOLD}./init.sh${NC} to bootstrap your project"
echo -e "  ${CYAN}2.${NC} Commit ${BOLD}init.sh${NC} back to your repo"
echo -e "  ${CYAN}3.${NC} Start coding with ${BOLD}aider${NC}!"
echo ""