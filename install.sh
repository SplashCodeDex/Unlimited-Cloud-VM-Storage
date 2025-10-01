#!/bin/bash

# This script installs or uninstalls the 'workspace' command-line tool.
# It is designed to be portable, resilient, and to provide a rich out-of-the-box experience.

set -e # Exit on any error

# --- Configuration ---
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BIN_DIR="$INSTALL_DIR/bin"
SRC_SCRIPT="$INSTALL_DIR/scripts/workspace"
DEST_LINK="$BIN_DIR/workspace"
CONFIG_DIR="$HOME/.config/workspace"
CONFIG_SCRIPT="$CONFIG_DIR/workspace.sh"
WARM_SCRIPT_PATH="$INSTALL_DIR/scripts/warm_workspaces.sh"
BASHRC_TEMPLATE_PATH="$INSTALL_DIR/bash/.bashrc"

# --- Helper Functions ---

abort() {
    echo "Error: $1" >&2
    exit 1
}

check_dependencies() {
    # ... (function is unchanged, left for brevity) ...
}

install_oh_my_bash() {
    # ... (function is unchanged, left for brevity) ...
}

setup_shell_config() {
    # ... (function is unchanged, left for brevity) ...
}

update_user_profile() {
    # ... (function is unchanged, left for brevity) ...
}

setup_executable() {
    # ... (function is unchanged, left for brevity) ...
}

install() {
    echo "Starting installation of the 'workspace' tool..."
    check_dependencies
    install_oh_my_bash
    setup_shell_config
    update_user_profile
    setup_executable

    echo -e "\n--- Installation Complete ---"
    echo "To finish, please run: source ~/.bashrc"
}

uninstall() {
    echo "Starting uninstallation of the 'workspace' tool..."
    read -p "Are you sure you want to uninstall? This will remove the main command and configuration. [y/N] " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Uninstallation cancelled."
        exit 0
    fi

    # 1. Remove shell integration
    echo " - Removing shell profile integration..."
    local shell_profile="$HOME/.bashrc"
    local source_line_pattern="source.*$CONFIG_SCRIPT"
    local init_comment="# Initialize workspace tool"
    if [ -f "$shell_profile" ]; then
        sed -i.bak -e "/^${init_comment}$/{N;/${source_line_pattern}/d;}" "$shell_profile"
        # Clean up empty lines that might be left
        sed -i.bak 'G;/^\s*$/d' "$shell_profile"
        rm -f "${shell_profile}.bak"
        echo "  - Removed integration from $shell_profile."
    fi

    # 2. Remove executable and bin directory
    echo " - Removing executable link..."
    if [ -L "$DEST_LINK" ]; then
        rm "$DEST_LINK"
        echo "  - Removed $DEST_LINK."
    fi
    if [ -d "$BIN_DIR" ] && [ -z "$(ls -A "$BIN_DIR")" ]; then
        rmdir "$BIN_DIR"
        echo "  - Removed empty bin directory."
    fi

    # 3. Remove config directory
    echo " - Removing configuration directory..."
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        echo "  - Removed $CONFIG_DIR."
    fi

    # 4. Ask to remove user data
    local WORKSPACE_BASE_DIR="$HOME/Workspaces"
    local EPHEMERAL_CACHE_DIR="$HOME/.cache/ephemeral_workspaces"
    local DB_FILE="$HOME/.workspace_history.db"

    echo " - The uninstaller can also remove user-generated data."
    read -p "  - Delete all workspaces in '$WORKSPACE_BASE_DIR'? THIS IS IRREVERSIBLE. [y/N] " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then rm -rf "$WORKSPACE_BASE_DIR" && echo "    - Removed workspaces directory."; fi

    read -p "  - Delete the ephemeral cache in '$EPHEMERAL_CACHE_DIR'? THIS IS IRREVERSIBLE. [y/N] " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then rm -rf "$EPHEMERAL_CACHE_DIR" && echo "    - Removed ephemeral cache."; fi

    read -p "  - Delete the workspace history database ('$DB_FILE')? [y/N] " -n 1 -r; echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then rm -f "$DB_FILE" && echo "    - Removed history database."; fi

    echo -e "\n--- Uninstallation Complete ---"
    echo "Please run 'source ~/.bashrc' to finalize the process."
    echo "You can now safely delete the installation directory: $INSTALL_DIR"
}


# --- Main Script ---
if [ "$(id -u)" -eq 0 ]; then abort "This script must not be run as root."; fi

if [ "$1" = "--uninstall" ]; then
    uninstall
else
    install
fi
