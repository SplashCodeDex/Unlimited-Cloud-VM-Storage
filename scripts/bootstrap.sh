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

echo_info "Installing dependencies (git, stow)..."
sudo apt-get install -y git stow
echo_success "Dependencies installed."

# --- Dotfiles Setup ---
# The directory where this script is located.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo_info "Running setup_dotfiles.sh to create symlinks..."
"$SCRIPT_DIR/setup_dotfiles.sh"
echo_success "Dotfiles setup complete."

echo "🎉 Bootstrap process finished successfully!"
