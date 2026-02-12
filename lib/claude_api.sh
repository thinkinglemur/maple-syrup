#!/usr/bin/env bash
# lib/claude_api.sh – Claude API key prompt and stack suggestion call

ANTHROPIC_API_KEY=""

prompt_claude_api_key() {
  # Check env first
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    ok "Using ANTHROPIC_API_KEY from environment"
    return
  fi

  # Check .env file
  if [[ -f ".env" ]] && grep -q "ANTHROPIC_API_KEY" .env; then
    ANTHROPIC_API_KEY=$(grep "ANTHROPIC_API_KEY" .env | cut -d '=' -f2- | tr -d '"'"'" | xargs)
    ok "Loaded ANTHROPIC_API_KEY from .env"
    return
  fi

  echo ""
  ask "Enter your Anthropic API key (sk-ant-...):"
  read -r -s ANTHROPIC_API_KEY
  echo ""

  if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    error "API key cannot be empty"
    exit 1
  fi

  if [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant- ]]; then
    warn "Key doesn't look like an Anthropic key (expected sk-ant-...) — continuing anyway"
  fi

  # Persist to .env
  echo "ANTHROPIC_API_KEY=$ANTHROPIC_API_KEY" >> .env
  ok "API key saved to .env"

  export ANTHROPIC_API_KEY
}

# ── Ask Claude to analyse the synopsis and return JSON ──────────────────────
claude_suggest_stack() {
  local synopsis="$1"
  local api_key="$2"

  local system_prompt='You are a senior software architect. Analyse the project synopsis and return ONLY a JSON object (no markdown, no explanation) with these exact keys:
{
  "language": "TypeScript|Python|Rust|Go|PHP",
  "framework": "<framework name>",
  "database": "<db name or null>",
  "cache": "<Redis|Memcached|null>",
  "deploy_target": "AWS ECS Fargate|Vercel|Railway",
  "reasoning": "<one sentence why>"
}'

  local payload
  payload=$(jq -n \
    --arg system "$system_prompt" \
    --arg synopsis "$synopsis" \
    '{
      model: "claude-3-5-sonnet-20241022",
      max_tokens: 512,
      system: $system,
      messages: [{ role: "user", content: $synopsis }]
    }')

  local response
  response=$(curl -s https://api.anthropic.com/v1/messages \
    -H "x-api-key: $api_key" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$payload")

  # Extract the text content
  local text
  text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)

  if [[ -z "$text" ]]; then
    error "Failed to get a response from Claude. Check your API key and try again."
    echo "Raw response: $response" >&2
    exit 1
  fi

  echo "$text"
}

# ── Parse the JSON suggestions into global vars ──────────────────────────────
SUGGESTED_LANGUAGE=""
SUGGESTED_FRAMEWORK=""
SUGGESTED_DATABASE=""
SUGGESTED_CACHE=""
SUGGESTED_DEPLOY=""
SUGGESTED_REASONING=""

parse_suggestions() {
  local json="$1"

  SUGGESTED_LANGUAGE=$(echo "$json"  | jq -r '.language  // "TypeScript"')
  SUGGESTED_FRAMEWORK=$(echo "$json" | jq -r '.framework // "Next.js"')
  SUGGESTED_DATABASE=$(echo "$json"  | jq -r '.database  // "null"')
  SUGGESTED_CACHE=$(echo "$json"     | jq -r '.cache     // "null"')
  SUGGESTED_DEPLOY=$(echo "$json"    | jq -r '.deploy_target // "AWS ECS Fargate"')
  SUGGESTED_REASONING=$(echo "$json" | jq -r '.reasoning // ""')

  # Normalise "null" string to empty
  [[ "$SUGGESTED_DATABASE" == "null" ]] && SUGGESTED_DATABASE=""
  [[ "$SUGGESTED_CACHE"    == "null" ]] && SUGGESTED_CACHE=""
}
