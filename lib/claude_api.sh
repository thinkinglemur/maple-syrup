#!/usr/bin/env bash
# lib/claude_api.sh – Claude API key prompt and stack suggestion call

ANTHROPIC_API_KEY=""
CLAUDE_RESULT_FILE=""

prompt_claude_api_key() {
  # Check env first
  if [[ -n "${ANTHROPIC_API_KEY:-}" ]]; then
    ok "Using ANTHROPIC_API_KEY from environment"
    return
  fi

  # Check .env file
  if [[ -f ".env" ]] && grep -q "ANTHROPIC_API_KEY" .env; then
    ANTHROPIC_API_KEY=$(grep "ANTHROPIC_API_KEY" .env | cut -d '=' -f2- | tr -d '"'"'" | xargs)
    if [[ -n "$ANTHROPIC_API_KEY" ]]; then
      ok "Loaded ANTHROPIC_API_KEY from .env"
      export ANTHROPIC_API_KEY
      return
    fi
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

# ── Spinner ───────────────────────────────────────────────────────────────────
_spinner() {
  local pid=$1
  local msg="${2:-Thinking...}"
  local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
  local i=0
  tput civis 2>/dev/null || true
  while kill -0 "$pid" 2>/dev/null; do
    local c="${spin:$((i % ${#spin})):1}"
    printf "\r  ${CYAN}%s${NC}  %s" "$c" "$msg"
    sleep 0.1
    i=$(( i + 1 ))
  done
  printf "\r\033[K"
  tput cnorm 2>/dev/null || true
}

# ── Ask Claude to analyse the synopsis and return JSON ────────────────────────
claude_suggest_stack() {
  local synopsis="$1"
  local api_key="$2"

  local system_prompt='You are a senior software architect. Analyse the project synopsis and return ONLY a valid JSON object (no markdown, no code fences, no explanation) with these exact keys:
{
  "language": "TypeScript",
  "framework": "Next.js",
  "database": "PostgreSQL",
  "cache": "Redis",
  "deploy_target": "AWS ECS Fargate",
  "reasoning": "one sentence explaining choices"
}
Rules:
- language must be one of: TypeScript, Python, Rust, Go, PHP
- framework must suit the chosen language
- database can be: PostgreSQL, MySQL, MongoDB, SQLite, Supabase, PlanetScale, or null
- cache can be: Redis, Memcached, or null
- deploy_target must be one of: AWS ECS Fargate, Vercel, Railway
- Return ONLY the JSON object, nothing else'

  # Build JSON payload safely via jq (handles special chars in synopsis)
  local payload
  if ! payload=$(jq -n \
    --arg system "$system_prompt" \
    --arg content "$synopsis" \
    '{
      model: "claude-sonnet-4-5-20250929",
      max_tokens: 512,
      system: $system,
      messages: [{ role: "user", content: $content }]
    }' 2>&1); then
    error "Failed to build API payload: $payload"
    exit 1
  fi

  # Make the API call in background so we can show a spinner
  local tmp_response tmp_err
  tmp_response=$(mktemp)
  tmp_err=$(mktemp)

  curl -s --max-time 30 \
    https://api.anthropic.com/v1/messages \
    -H "x-api-key: $api_key" \
    -H "anthropic-version: 2023-06-01" \
    -H "content-type: application/json" \
    -d "$payload" \
    > "$tmp_response" 2>"$tmp_err" &

  local curl_pid=$!
  _spinner "$curl_pid" "Asking Claude to analyse your project..."
  wait "$curl_pid"
  local curl_exit=$?

  local response
  response=$(cat "$tmp_response")
  rm -f "$tmp_response" "$tmp_err"

  # Check curl succeeded
  if [[ $curl_exit -ne 0 ]]; then
    error "Network request failed (curl exit $curl_exit). Check your internet connection."
    exit 1
  fi

  # Check for API-level errors
  local api_error
  api_error=$(echo "$response" | jq -r '.error.message // empty' 2>/dev/null)
  if [[ -n "$api_error" ]]; then
    error "Claude API error: $api_error"
    local err_type
    err_type=$(echo "$response" | jq -r '.error.type // ""' 2>/dev/null)
    if [[ "$err_type" == "authentication_error" ]]; then
      echo ""
      echo "  Your API key appears to be invalid."
      echo "  Delete .env and re-run setup.sh to re-enter it."
    fi
    exit 1
  fi

  # Extract text content
  local text
  text=$(echo "$response" | jq -r '.content[0].text // empty' 2>/dev/null)

  if [[ -z "$text" ]]; then
    error "Unexpected empty response from Claude."
    echo "  Raw response:" >&2
    echo "$response" | jq . 2>/dev/null || echo "$response" >&2
    exit 1
  fi

  # Strip any accidental markdown fences
  text=$(echo "$text" | sed 's/^```json[[:space:]]*//' | sed 's/^```[[:space:]]*//' | sed 's/```[[:space:]]*$//')

  # Write result to file (avoids subshell stdout-capture swallowing spinner output)
  echo "$text" > "$CLAUDE_RESULT_FILE"
}

# ── Parse JSON suggestions into global vars ───────────────────────────────────
SUGGESTED_LANGUAGE=""
SUGGESTED_FRAMEWORK=""
SUGGESTED_DATABASE=""
SUGGESTED_CACHE=""
SUGGESTED_DEPLOY=""
SUGGESTED_REASONING=""

parse_suggestions() {
  local json="$1"

  # Validate it's actually JSON before parsing
  if ! echo "$json" | jq . >/dev/null 2>&1; then
    error "Claude returned invalid JSON:"
    echo "$json" >&2
    exit 1
  fi

  SUGGESTED_LANGUAGE=$(echo "$json"  | jq -r '.language      // "TypeScript"')
  SUGGESTED_FRAMEWORK=$(echo "$json" | jq -r '.framework     // "Next.js"')
  SUGGESTED_DATABASE=$(echo "$json"  | jq -r '.database      // "null"')
  SUGGESTED_CACHE=$(echo "$json"     | jq -r '.cache         // "null"')
  SUGGESTED_DEPLOY=$(echo "$json"    | jq -r '.deploy_target // "AWS ECS Fargate"')
  SUGGESTED_REASONING=$(echo "$json" | jq -r '.reasoning     // ""')

  # Normalise "null" string to empty
  [[ "$SUGGESTED_DATABASE" == "null" ]] && SUGGESTED_DATABASE=""
  [[ "$SUGGESTED_CACHE"    == "null" ]] && SUGGESTED_CACHE=""
}