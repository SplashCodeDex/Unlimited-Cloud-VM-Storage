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
    local spinstr='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local delay=0.05
    local start_time=$(date +%s)

    echo -n "$message " >&2
    while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
        local temp=${spinstr#?}
        printf " [%c]  " "$spinstr" >&2
        local spinstr=$temp${spinstr%"$temp"}
        sleep $delay
        printf "\b\b\b\b\b\b" >&2
    done

    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local min_duration=1 # Minimum spinner duration in seconds

    if [ "$duration" -lt "$min_duration" ]; then
        if command -v bc &>/dev/null; then
            sleep $(echo "$min_duration - $duration" | bc)
        else
            sleep 1
        fi
    fi

    printf "    \b\b\b\b" >&2
    echo " " >&2
}

# --- Progress Bar ---
progress_bar() {
    local duration=${1}
    already_done() { for ((done=0; done<$elapsed; done++)); do printf "▇"; done }
    remaining() { for ((remain=$elapsed; remain<$total; remain++)); do printf " "; done }
    percentage() { printf "| %s%%" $(( (($elapsed)*100)/($total)*100/100 )); }
    clean_line() { printf "\r"; }

    local total=30
    local elapsed=0
    while [ $elapsed -lt $total ]; do
        already_done; remaining; percentage
        sleep $(($duration/$total))
        elapsed=$(($elapsed+1))
        clean_line
    done
    clean_line
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