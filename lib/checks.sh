#!/usr/bin/env bash
# lib/checks.sh – verify required tools are installed

check_dependencies() {
  local missing=()
  local deps=("curl" "jq" "git")

  for dep in "${deps[@]}"; do
    if ! command -v "$dep" &>/dev/null; then
      missing+=("$dep")
    fi
  done

  if [[ ${#missing[@]} -gt 0 ]]; then
    error "Missing required dependencies: ${missing[*]}"
    echo ""
    echo "  Please install them and re-run setup.sh:"
    for dep in "${missing[@]}"; do
      case "$dep" in
        curl) echo "    brew install curl  /  apt install curl";;
        jq)   echo "    brew install jq    /  apt install jq";;
        git)  echo "    brew install git   /  apt install git";;
      esac
    done
    echo ""
    exit 1
  fi

  ok "curl, jq, git – all present"
}
