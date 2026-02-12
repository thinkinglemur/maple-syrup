#!/usr/bin/env bash
# lib/prompts.sh – interactive review & override of stack suggestions

# Final chosen values (set after review)
CHOSEN_LANGUAGE=""
CHOSEN_FRAMEWORK=""
CHOSEN_DATABASE=""
CHOSEN_CACHE=""
CHOSEN_DEPLOY=""
PROJECT_NAME=""

# ─────────────────────────────────────────────────────────────
#  Language options
# ─────────────────────────────────────────────────────────────
LANGUAGES=("TypeScript" "Python" "Rust" "Go" "PHP")

# bash 3 compatible framework lookup (macOS ships with bash 3.2, no associative arrays)
get_frameworks() {
  case "$1" in
    TypeScript) echo "Next.js Remix Express Fastify NestJS" ;;
    Python)     echo "FastAPI Django Flask" ;;
    Rust)       echo "Axum Actix-web" ;;
    Go)         echo "Gin Echo Fiber" ;;
    PHP)        echo "Laravel Symfony" ;;
    *)          echo "Next.js" ;;
  esac
}

DATABASES=("PostgreSQL" "MySQL" "MongoDB" "SQLite" "Supabase" "PlanetScale" "None")
CACHES=("Redis" "Memcached" "None")
DEPLOY_TARGETS=("AWS ECS Fargate" "Vercel" "Railway")

# ─────────────────────────────────────────────────────────────
#  Helper: select from a numbered list
#  Usage: select_from_list "Prompt" "default" item1 item2 ...
#  Sets SELECTION to the chosen item
# ─────────────────────────────────────────────────────────────
SELECTION=""
select_from_list() {
  local prompt="$1"
  local default="$2"
  shift 2
  local items=("$@")

  echo ""
  echo -e "  ${BOLD}$prompt${NC}"
  local i=1
  local default_idx=1
  for item in "${items[@]}"; do
    if [[ "$item" == "$default" ]]; then
      echo -e "    ${GREEN}$i) $item  ← suggested${NC}"
      default_idx=$i
    else
      echo "    $i) $item"
    fi
    ((i++))
  done
  echo ""
  ask "Choose [1-$((i-1))] (default: $default_idx):"
  read -r choice
  [[ -z "$choice" ]] && choice=$default_idx

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#items[@]} )); then
    warn "Invalid choice, using default: $default"
    SELECTION="$default"
  else
    SELECTION="${items[$((choice-1))]}"
  fi
}

# ─────────────────────────────────────────────────────────────
review_suggestions() {
  echo ""
  echo -e "  ${BOLD}Claude suggests the following stack:${NC}"
  echo -e "  ${DIM}$SUGGESTED_REASONING${NC}"
  echo ""
  echo -e "  Language  : ${CYAN}$SUGGESTED_LANGUAGE${NC}"
  echo -e "  Framework : ${CYAN}$SUGGESTED_FRAMEWORK${NC}"
  echo -e "  Database  : ${CYAN}${SUGGESTED_DATABASE:-None}${NC}"
  echo -e "  Cache     : ${CYAN}${SUGGESTED_CACHE:-None}${NC}"
  echo -e "  Deploy    : ${CYAN}$SUGGESTED_DEPLOY${NC}"
  echo ""
  ask "Accept suggestions? [Y/n]:"
  read -r accept

  # ── Project name ────────────────────────────────────────────
  echo ""
  ask "Project name (e.g. my-app):"
  read -r PROJECT_NAME
  PROJECT_NAME="${PROJECT_NAME:-my-app}"
  # Slugify
  PROJECT_NAME=$(echo "$PROJECT_NAME" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9-]/-/g' | sed 's/--*/-/g' | sed 's/^-\|-$//g')
  ok "Project name: $PROJECT_NAME"

  if [[ "${accept:-y}" =~ ^[Yy]$ ]] || [[ -z "$accept" ]]; then
    CHOSEN_LANGUAGE="$SUGGESTED_LANGUAGE"
    CHOSEN_FRAMEWORK="$SUGGESTED_FRAMEWORK"
    CHOSEN_DATABASE="$SUGGESTED_DATABASE"
    CHOSEN_CACHE="$SUGGESTED_CACHE"
    CHOSEN_DEPLOY="$SUGGESTED_DEPLOY"
    ok "Using suggested stack"
    return
  fi

  # ── Override: Language ──────────────────────────────────────
  select_from_list "Language:" "$SUGGESTED_LANGUAGE" "${LANGUAGES[@]}"
  CHOSEN_LANGUAGE="$SELECTION"

  # ── Override: Framework ─────────────────────────────────────
  local fw_list
  read -ra fw_list <<< "$(get_frameworks "$CHOSEN_LANGUAGE")"
  local fw_default="${fw_list[0]}"
  # If suggested framework is in the list, use it as default
  for fw in "${fw_list[@]}"; do
    [[ "$fw" == "$SUGGESTED_FRAMEWORK" ]] && fw_default="$SUGGESTED_FRAMEWORK"
  done
  select_from_list "Framework for $CHOSEN_LANGUAGE:" "$fw_default" "${fw_list[@]}"
  CHOSEN_FRAMEWORK="$SELECTION"

  # ── Override: Database ──────────────────────────────────────
  local db_default="${SUGGESTED_DATABASE:-None}"
  select_from_list "Primary Database:" "$db_default" "${DATABASES[@]}"
  CHOSEN_DATABASE="$SELECTION"
  [[ "$CHOSEN_DATABASE" == "None" ]] && CHOSEN_DATABASE=""

  # ── Override: Cache ─────────────────────────────────────────
  local cache_default="${SUGGESTED_CACHE:-None}"
  select_from_list "Caching Layer:" "$cache_default" "${CACHES[@]}"
  CHOSEN_CACHE="$SELECTION"
  [[ "$CHOSEN_CACHE" == "None" ]] && CHOSEN_CACHE=""

  # ── Override: Deploy ────────────────────────────────────────
  select_from_list "Deploy target:" "$SUGGESTED_DEPLOY" "${DEPLOY_TARGETS[@]}"
  CHOSEN_DEPLOY="$SELECTION"

  echo ""
  ok "Stack confirmed:"
  echo -e "  Language  : ${CYAN}$CHOSEN_LANGUAGE${NC}"
  echo -e "  Framework : ${CYAN}$CHOSEN_FRAMEWORK${NC}"
  echo -e "  Database  : ${CYAN}${CHOSEN_DATABASE:-None}${NC}"
  echo -e "  Cache     : ${CYAN}${CHOSEN_CACHE:-None}${NC}"
  echo -e "  Deploy    : ${CYAN}$CHOSEN_DEPLOY${NC}"
}