#!/bin/bash
set -e

# This script bootstraps a new machine with the user's dotfiles and dependencies.

echo "🚀 Starting bootstrap process..."

# --- Helper Functions ---
echo_info() {
    echo "[INFO] $1"
}

echo_success() {
    echo "✅ $1"
}

# --- Dependency Installation (Debian/Ubuntu) ---
echo_info "Updating package list..."
sudo apt-get update

echo_info "Checking for dependencies..."

if ! command -v git &> /dev/null; then
    echo_info "Installing git..."
    sudo apt-get install -y git
    echo_success "git installed."
else
    echo_success "git is already installed."
fi

if ! command -v stow &> /dev/null; then
    echo_info "Installing stow..."
    sudo apt-get install -y stow
    echo_success "stow installed."
else
    echo_success "stow is already installed."
fi

# --- Dotfiles Setup ---
# The directory where this script is located.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo_info "Running setup_dotfiles.sh to create symlinks..."
"$SCRIPT_DIR/setup_dotfiles.sh"
echo_success "Dotfiles setup complete."

echo "🎉 Bootstrap process finished successfully!"
