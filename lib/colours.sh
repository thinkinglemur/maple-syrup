#!/usr/bin/env bash
# lib/colours.sh – ANSI colour helpers

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Colour

step()  { echo -e "\n${BOLD}${CYAN}▶ $1${NC}"; }
info()  { echo -e "  ${DIM}$1${NC}"; }
ok()    { echo -e "  ${GREEN}✔ $1${NC}"; }
warn()  { echo -e "  ${YELLOW}⚠ $1${NC}"; }
error() { echo -e "  ${RED}✖ $1${NC}"; }
ask()   { echo -e "  ${YELLOW}? $1${NC}"; }
