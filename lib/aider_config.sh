#!/usr/bin/env bash
# lib/aider_config.sh – write .aider.conf.yml and .aider.model.settings.yml

AIDER_MODEL=""
AIDER_EDITOR_MODE=""

configure_aider() {
  echo ""
  echo -e "  ${BOLD}Aider model:${NC}"
  echo "    1) claude-sonnet-4-5-20250929  ← default (fast, great for most tasks)"
  echo "    2) gpt-4o"
  echo "    3) gemini/gemini-2.5-pro"
  echo ""
  ask "Choose model [1-3] (default: 1):"
  read -r model_choice

  case "${model_choice:-1}" in
    1) AIDER_MODEL="claude-sonnet-4-5-20250929" ;;
    2) AIDER_MODEL="gpt-4o" ;;
    3) AIDER_MODEL="gemini/gemini-2.5-pro" ;;
    *) AIDER_MODEL="claude-sonnet-4-5-20250929" ;;
  esac

  # ── Prompt for the model's API key ────────────────────────────
  _prompt_model_api_key

  echo ""
  echo -e "  ${BOLD}Aider editor mode:${NC}"
  echo "    1) ask    ← default (Claude proposes edits, you approve)"
  echo "    2) diff   (inline unified diffs, apply automatically)"
  echo "    3) whole  (rewrites whole file)"
  echo ""
  ask "Choose mode [1-3] (default: 1):"
  read -r mode_choice

  case "${mode_choice:-1}" in
    1) AIDER_EDITOR_MODE="ask"   ;;
    2) AIDER_EDITOR_MODE="diff"  ;;
    3) AIDER_EDITOR_MODE="whole" ;;
    *) AIDER_EDITOR_MODE="ask"   ;;
  esac

  _write_aider_conf
  _write_aider_model_settings
  ok "Aider configured → .aider.conf.yml + .aider.model.settings.yml"
}

_prompt_model_api_key() {
  local env_var label url existing

  case "$AIDER_MODEL" in
    claude-*)
      env_var="ANTHROPIC_API_KEY"
      label="Anthropic"
      url="https://console.anthropic.com/settings/keys"
      ;;
    gpt-*)
      env_var="OPENAI_API_KEY"
      label="OpenAI"
      url="https://platform.openai.com/api-keys"
      ;;
    gemini/*)
      env_var="GEMINI_API_KEY"
      label="Google Gemini"
      url="https://aistudio.google.com/app/apikey"
      ;;
  esac

  echo ""

  # Check if already set in env or .env file
  existing="${!env_var:-}"
  if [[ -z "$existing" && -f ".env" ]]; then
    existing=$(grep "^${env_var}=" .env 2>/dev/null | cut -d'=' -f2- | tr -d '"'"'" | xargs)
  fi

  if [[ -n "$existing" ]]; then
    ok "${env_var} already set — skipping"
    # Make sure it's exported for aider to pick up
    export "${env_var}=${existing}"
    return
  fi

  echo -e "  ${BOLD}${label} API key required for ${AIDER_MODEL}${NC}"
  echo -e "  ${DIM}Get one at: ${url}${NC}"
  echo ""
  ask "Enter your ${label} API key:"
  read -r -s model_api_key
  echo ""

  if [[ -z "$model_api_key" ]]; then
    warn "${env_var} not set — aider will prompt for it when you run it"
    return
  fi

  # Save to .env (append if not already present)
  if [[ -f ".env" ]] && grep -q "^${env_var}=" .env; then
    # Update existing line
    sed -i.bak "s|^${env_var}=.*|${env_var}=${model_api_key}|" .env && rm -f .env.bak
  else
    echo "${env_var}=${model_api_key}" >> .env
  fi

  export "${env_var}=${model_api_key}"
  ok "${env_var} saved to .env"
}

_write_aider_conf() {
  local weak_model
  case "$AIDER_MODEL" in
    claude-*) weak_model="claude-haiku-4-5-20251001" ;;
    gpt-*)    weak_model="gpt-4o-mini" ;;
    gemini/*) weak_model="gemini/gemini-2.0-flash" ;;
    *)        weak_model="claude-haiku-4-5-20251001" ;;
  esac

  cat > .aider.conf.yml <<EOF
## .aider.conf.yml
## See: https://aider.chat/docs/config/aider_conf.html

# ── Model ─────────────────────────────────────
model: $AIDER_MODEL
weak-model: $weak_model
editor-model: $AIDER_MODEL
edit-format: $AIDER_EDITOR_MODE

# ── Behaviour ─────────────────────────────────
auto-commits: true
dirty-commits: true
attribute-author: false
attribute-committer: false

# ── Context ───────────────────────────────────
auto-read-files: true

# ── Output ────────────────────────────────────
pretty: true
stream: true
EOF
}

_write_aider_model_settings() {
  cat > .aider.model.settings.yml <<EOF
## .aider.model.settings.yml
## Advanced per-model settings
## See: https://aider.chat/docs/config/adv-model-settings.html
##      https://aider.chat/docs/config/reasoning.html

- name: claude-sonnet-4-5-20250929
  edit_format: diff
  weak_model_name: claude-haiku-4-5-20251001
  use_repo_map: true
  send_undo_reply: true
  lazy: false
  reminder: sys
  examples_as_sys_msg: false

- name: claude-haiku-4-5-20251001
  edit_format: whole
  weak_model_name: claude-haiku-4-5-20251001
  use_repo_map: false

- name: gpt-4o
  edit_format: diff
  weak_model_name: gpt-4o-mini
  use_repo_map: true
  send_undo_reply: true
  lazy: false
  reminder: sys
  examples_as_sys_msg: true

- name: gpt-4o-mini
  edit_format: whole
  weak_model_name: gpt-4o-mini
  use_repo_map: false

- name: gemini/gemini-2.5-pro
  edit_format: diff
  weak_model_name: gemini/gemini-2.0-flash
  use_repo_map: true
  send_undo_reply: true
  lazy: false
  reminder: sys
  # Gemini 2.5 Pro supports extended thinking
  thinking_tokens: 8000

- name: gemini/gemini-2.0-flash
  edit_format: whole
  weak_model_name: gemini/gemini-2.0-flash
  use_repo_map: false
EOF
}