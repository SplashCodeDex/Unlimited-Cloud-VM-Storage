#!/bin/bash
set -e

# This script sets up the dotfiles by creating symlinks using GNU Stow.

# The directory where this script is located.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# The dotfiles directory is the parent of the scripts directory.
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# The target directory for the symlinks.
TARGET_DIR="$HOME"

# The packages to stow.
PACKAGES="bash git history oh-my-bash"

# Run stow to create the symlinks.
stow --dir="$DOTFILES_DIR" --target="$TARGET_DIR" $PACKAGES

echo "✅ Dotfiles have been successfully stowed."
