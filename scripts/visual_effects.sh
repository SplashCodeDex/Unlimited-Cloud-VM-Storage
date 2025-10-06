#!/bin/bash

# --- Visual Effects ---

# --- Colors ---
export COLOR_RESET='\033[0m'
export COLOR_RED='\033[0;31m'
export COLOR_GREEN='\033[0;32m'
export COLOR_YELLOW='\033[0;33m'
export COLOR_BLUE='\033[0;34m'
export COLOR_PURPLE='\033[0;35m'
export COLOR_CYAN='\033[0;36m'
export COLOR_WHITE='\033[0;37m'

# --- Text Formatting ---
export TEXT_BOLD=$(tput bold)
export TEXT_RESET=$(tput sgr0)

# --- Spinner ---
spinner() {
    if [ "$ANIMATIONS_ENABLED" = false ]; then
        return
    fi

    local pid=$1
    local message=$2
    local spinstr='|/-\'
    local delay=0.1

    echo -n "$message " >&2
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        for i in $(seq 0 3); do
            printf "[%c]" "${spinstr:$i:1}" >&2
            sleep $delay
            printf "\b\b\b" >&2
        done
    done
    printf "   \b\b\b" >&2
    echo "" >&2
}

# --- Progress Bar ---
progress_bar() {
    local duration=${1}
    local total=30
    local elapsed=0

    while [ $elapsed -lt $total ]; do
        elapsed=$(($elapsed+1))
        local percentage=$(( ($elapsed*100)/$total ))
        local done_length=$(( ($percentage*$total)/100 ))
        local remaining_length=$(( $total-$done_length ))
        local done_bar=$(printf "%${done_length}s" | tr ' ' '▇')
        local remaining_bar=$(printf "%${remaining_length}s" | tr ' ' ' ')
        printf "[\%s\%s] %d%%" "$done_bar" "$remaining_bar" "$percentage"
        sleep $(echo "$duration/$total" | bc -l)
    done
    echo ""
}

# --- Dots ---
dots() {
    local message=$1
    echo -n "$message" >&2
    for i in {1..3}; do
        echo -n "." >&2
        sleep 0.5
    done
    echo "" >&2
}

# --- Print Functions ---
print_success() {
    printf "${COLOR_GREEN}✓ %s${COLOR_RESET}\n" "$1" >&2
}

print_error() {
    printf "${COLOR_RED}✗ %s${COLOR_RESET}\n" "$1" >&2
}

print_warning() {
    printf "${COLOR_YELLOW}⚠ %s${COLOR_RESET}\n" "$1" >&2
}

print_info() {
    printf "${COLOR_BLUE}ℹ %s${COLOR_RESET}\n" "$1" >&2
}