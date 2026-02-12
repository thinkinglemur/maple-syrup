#!/usr/bin/env bash
# lib/git_setup.sh – git init and .gitignore

setup_git() {
  ask "Initialise a new git repo here? [Y/n]:"
  read -r do_git
  if [[ "${do_git:-y}" =~ ^[Nn]$ ]]; then
    info "Skipping git init"
    return
  fi

  if [[ ! -d ".git" ]]; then
    git init -q
    ok "git init"
  else
    ok "git repo already initialised"
  fi

  _write_gitignore
  ok ".gitignore written"
}

_write_gitignore() {
  # Base entries that should always be present
  local base_entries=(
    "# Secrets"
    ".env"
    ".env.*"
    "!.env.example"
    ""
    "# Aider"
    ".aider*"
    "!.aider.conf.yml"
    "!.aider.model.settings.yml"
    ""
    "# OS"
    ".DS_Store"
    "Thumbs.db"
    ""
    "# Editor"
    ".vscode/"
    ".idea/"
    "*.swp"
    "*.swo"
  )

  local lang_entries=()

  case "$CHOSEN_LANGUAGE" in
    TypeScript|JavaScript)
      lang_entries=(
        ""
        "# Node"
        "node_modules/"
        "dist/"
        ".next/"
        "out/"
        ".cache/"
        "*.tsbuildinfo"
        "coverage/"
        ".turbo/"
      )
      ;;
    Python)
      lang_entries=(
        ""
        "# Python"
        "__pycache__/"
        "*.py[cod]"
        "*.pyo"
        ".venv/"
        "venv/"
        "env/"
        "*.egg-info/"
        "dist/"
        "build/"
        ".pytest_cache/"
        ".mypy_cache/"
        ".ruff_cache/"
        "htmlcov/"
        ".coverage"
      )
      ;;
    Rust)
      lang_entries=(
        ""
        "# Rust"
        "target/"
        "Cargo.lock"
      )
      ;;
    Go)
      lang_entries=(
        ""
        "# Go"
        "bin/"
        "vendor/"
        "*.test"
        "*.out"
      )
      ;;
    PHP)
      lang_entries=(
        ""
        "# PHP / Composer"
        "vendor/"
        "*.log"
        "storage/logs/"
        "bootstrap/cache/"
        ".phpunit.result.cache"
      )
      ;;
  esac

  local docker_entries=(
    ""
    "# Docker"
    "*.env.docker"
  )

  # Merge and write (preserving any existing .gitignore entries)
  if [[ -f ".gitignore" ]]; then
    info ".gitignore already exists – appending new entries only"
    {
      printf '\n# ── Added by project-bootstrap ──\n'
      for entry in "${base_entries[@]}" "${lang_entries[@]}" "${docker_entries[@]}"; do
        # Only add if line not already present
        if [[ -n "$entry" ]] && ! grep -qF "$entry" .gitignore 2>/dev/null; then
          echo "$entry"
        elif [[ -z "$entry" ]]; then
          echo ""
        fi
      done
    } >> .gitignore
  else
    {
      for entry in "${base_entries[@]}" "${lang_entries[@]}" "${docker_entries[@]}"; do
        echo "$entry"
      done
    } > .gitignore
  fi
}
