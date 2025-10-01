#!/bin/bash

# This script installs or uninstalls the 'workspace' command-line tool.
# It is designed to be portable, resilient, and to provide a rich out-of-the-box experience.

set -e # Exit on any error

# --- Globals ---
NON_INTERACTIVE=false

# --- Configuration ---
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BIN_DIR="$INSTALL_DIR/bin"
SRC_SCRIPT="$INSTALL_DIR/scripts/workspace"
DEST_LINK="$BIN_DIR/workspace"
CONFIG_DIR="$HOME/.config/workspace"
CONFIG_SCRIPT="$CONFIG_DIR/workspace.sh"
WARM_SCRIPT_PATH="$INSTALL_DIR/scripts/warm_workspaces.sh"

# --- Helper Functions ---

show_help() {
    cat << EOF
Usage: $(basename "$0") [options]

Options:
  --uninstall        Uninstall the workspace tool.
  -y, --yes          Bypass all interactive prompts.
  --help             Show this help message.
EOF
}

abort() {
    echo "Error: $1" >&2
    exit 1
}

check_dependencies() {
    echo "(1/5) Checking for dependencies..."
    local core_deps=("git" "sqlite3" "rsync")
    local optional_deps=("fzf" "autojump")
    local all_deps=("${core_deps[@]}" "${optional_deps[@]}")
    local missing_deps=()

    for cmd in "${all_deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo "  - All dependencies are installed."
        return
    fi

    echo "Warning: The following dependencies are missing: ${missing_deps[*]}"

    local should_install=false
    if [ "$NON_INTERACTIVE" = true ]; then
        should_install=true
    else
        read -p "This script can attempt to install them for you. May I proceed? [Y/n] " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            should_install=true
        fi
    fi

    if [ "$should_install" = true ]; then
        local pm_base_cmd=""
        local needs_sudo=true
        if command -v apt-get &>/dev/null; then pm_base_cmd="apt-get install -y";
        elif command -v yum &>/dev/null; then pm_base_cmd="yum install -y";
        elif command -v dnf &>/dev/null; then pm_base_cmd="dnf install -y";
        elif command -v pacman &>/dev/null; then pm_base_cmd="pacman -S --noconfirm";
        elif command -v brew &>/dev/null; then pm_base_cmd="brew install"; needs_sudo=false; fi

        if [ -n "$pm_base_cmd" ]; then
            local install_cmd="$pm_base_cmd ${missing_deps[*]}"
            echo "  - Attempting to install missing dependencies..."
            if [ "$needs_sudo" = true ] && [ "$(id -u)" -ne 0 ]; then
                if ! command -v sudo &>/dev/null; then
                    echo "  - Warning: 'sudo' command not found. Cannot install dependencies."
                else
                    if ! sudo sh -c "$install_cmd"; then
                        echo "  - Warning: Dependency installation with sudo failed."
                    fi
                fi
            else
                if ! sh -c "$install_cmd"; then
                    echo "  - Warning: Dependency installation failed."
                fi
            fi
        else
            echo "  - Warning: Could not detect a supported package manager. Please install dependencies manually."
        fi
    fi

    # Final, more robust check for core dependencies
    local still_missing_core_deps=()
    for cmd in "${core_deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            still_missing_core_deps+=("$cmd")
        fi
    done

    if [ ${#still_missing_core_deps[@]} -gt 0 ]; then
        abort "The following core dependencies are still missing: ${still_missing_core_deps[*]}. Please install them and run this script again."
    fi
}

install_oh_my_shell() {
    local shell_name=$(basename "$SHELL")
    echo -e "\n(2/5) Checking for Oh My $shell_name..."
    if [ "$shell_name" = "bash" ]; then
        if [ ! -d "$HOME/.oh-my-bash" ]; then
            echo "  - Oh My Bash not found. Cloning..."
            if ! git clone https://github.com/ohmybash/oh-my-bash.git "$HOME/.oh-my-bash"; then
                abort "Failed to clone Oh My Bash."
            fi
        else
            echo "  - Oh My Bash is already installed."
        fi
    elif [ "$shell_name" = "zsh" ]; then
        if [ ! -d "$HOME/.oh-my-zsh" ]; then
            echo "  - Oh My Zsh not found. It is recommended to install it for the best experience."
            if [ "$NON_INTERACTIVE" = false ]; then
                read -p "Do you want to install Oh My Zsh now? [Y/n] " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
                fi
            fi
        else
            echo "  - Oh My Zsh is already installed."
        fi
    else
        echo "  - Skipping Oh My Shell installation for unsupported shell: $shell_name"
    fi
}

setup_shell_config() {
    echo -e "\n(3/5) Creating shell function and configuration..."
    mkdir -p "$CONFIG_DIR"
    cat << EOF > "$CONFIG_SCRIPT"
#!/bin/sh
# Auto-generated by the workspace installer.

workspace() {
    local executable="$DEST_LINK"
    local output=\$($executable "$@")
    local exit_code=\$?

    if [ \$exit_code -eq 0 ]; then
        if [[ "\$output" == "__cd__:*" ]]; then
            local dir_to_change_to=\${output#__cd__:}
            if [ -d "\$dir_to_change_to" ]; then
                cd "\$dir_to_change_to"
                # Smartly source project-specific shell config
                if [ -f ".bashrc" ]; then
                    source .bashrc
                elif [ -f ".zshrc" ]; then
                    source .zshrc
                fi
            else
                echo "Error: Target directory '\$dir_to_change_to' does not exist." >&2
            fi
        else
            echo "\$output"
        fi
    else
        echo "\$output" >&2
    fi
}

_warm_workspaces() {
    if [ -f \"$WARM_SCRIPT_PATH\" ] && [ -x \"$WARM_SCRIPT_PATH\" ]; then
        bash \"$WARM_SCRIPT_PATH\" &>/dev/null &
    fi
}
EOF
    echo "  - Created $CONFIG_SCRIPT"
}

update_user_profile() {
    echo -e "\n(4/5) Updating user's shell profile..."
    local shell_name=$(basename "$SHELL")
    local profile_files=()

    if [ "$shell_name" = "bash" ]; then
        if [ -f "$HOME/.bash_profile" ]; then
            profile_files+=("$HOME/.bash_profile")
        elif [ -f "$HOME/.bash_login" ]; then
            profile_files+=("$HOME/.bash_login")
        elif [ -f "$HOME/.profile" ]; then
            profile_files+=("$HOME/.profile")
        fi
        if [ -f "$HOME/.bashrc" ]; then
            profile_files+=("$HOME/.bashrc")
        fi
    elif [ "$shell_name" = "zsh" ]; then
        if [ -f "$HOME/.zshrc" ]; then
            profile_files+=("$HOME/.zshrc")
        fi
    else
        echo "Warning: Unsupported shell '$shell_name'. Manual configuration may be required." >&2
        return
    fi

    if [ ${#profile_files[@]} -eq 0 ]; then
        if [ "$shell_name" = "bash" ]; then
            echo "  - No existing bash profile found. Creating a new .bashrc..."
            touch "$HOME/.bashrc"
            profile_files+=("$HOME/.bashrc")
        elif [ "$shell_name" = "zsh" ]; then
            echo "  - No existing zsh profile found. Creating a new .zshrc..."
            touch "$HOME/.zshrc"
            profile_files+=("$HOME/.zshrc")
        fi
    fi

    local init_block="# >>> workspace tool initialize >>>\n# This block was automatically added by the workspace installer.\n# To remove, run 'install.sh --uninstall' or simply delete this block.\nif [ -f \"$CONFIG_SCRIPT\" ]; then\n    source \"$CONFIG_SCRIPT\"\nfi\n# <<< workspace tool initialize <<<
"

    for profile_file in "${profile_files[@]}"; do
        if ! grep -q "# >>> workspace tool initialize >>>" "$profile_file"; then
            echo "  - Adding workspace tool initialization to $profile_file..."
            printf "\n%s" "$init_block" >> "$profile_file"
        else
            echo "  - Workspace tool already initialized in $profile_file."
        fi
    done

    echo "  - Shell profile is up to date."
}

setup_executable() {
    echo -e "\n(5/5) Setting up executable..."
    mkdir -p "$BIN_DIR"
    chmod +x "$SRC_SCRIPT" "$WARM_SCRIPT_PATH"
    ln -sf "$SRC_SCRIPT" "$DEST_LINK"
    echo "  - Linked $SRC_SCRIPT to $DEST_LINK"
}

install() {
    echo "Starting installation of the 'workspace' tool..."
    check_dependencies
    install_oh_my_shell
    setup_shell_config
    update_user_profile
    setup_executable

    echo -e "\n--- Installation Complete ---"
    echo "To finish, please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
}

uninstall() {
    echo "Starting uninstallation of the 'workspace' tool..."

    if [ "$NON_INTERACTIVE" = false ]; then
        read -p "Are you sure you want to uninstall? This will remove the main command and configuration. [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Uninstallation cancelled."
            exit 0
        fi
    fi

    # 1. Remove shell integration
    echo " - Removing shell profile integration..."
    local shell_name=$(basename "$SHELL")
    local profile_files=()

    if [ "$shell_name" = "bash" ]; then
        if [ -f "$HOME/.bash_profile" ]; then profile_files+=("$HOME/.bash_profile"); fi
        if [ -f "$HOME/.bash_login" ]; then profile_files+=("$HOME/.bash_login"); fi
        if [ -f "$HOME/.profile" ]; then profile_files+=("$HOME/.profile"); fi
        if [ -f "$HOME/.bashrc" ]; then profile_files+=("$HOME/.bashrc"); fi
    elif [ "$shell_name" = "zsh" ]; then
        if [ -f "$HOME/.zshrc" ]; then profile_files+=("$HOME/.zshrc"); fi
    fi

    for profile_file in "${profile_files[@]}"; do
        if [ -f "$profile_file" ]; then
            echo "  - Removing integration from $profile_file."
            sed -i.bak '/^# >>> workspace tool initialize >>>/,/^# <<< workspace tool initialize <<</d' "$profile_file"
            rm -f "${profile_file}.bak"
        fi
    done

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
    if [ "$NON_INTERACTIVE" = false ]; then
        read -p "  - Delete all workspaces in '$WORKSPACE_BASE_DIR'? THIS IS IRREVERSIBLE. [y/N] " -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then rm -rf "$WORKSPACE_BASE_DIR" && echo "    - Removed workspaces directory."; fi

        read -p "  - Delete the ephemeral cache in '$EPHEMERAL_CACHE_DIR'? THIS IS IRREVERSIBLE. [y/N] " -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then rm -rf "$EPHEMERAL_CACHE_DIR" && echo "    - Removed ephemeral cache."; fi

        read -p "  - Delete the workspace history database ('$DB_FILE')? [y/N] " -n 1 -r; echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then rm -f "$DB_FILE" && echo "    - Removed history database."; fi
    fi

    # 5. Unload shell functions
    echo " - Unloading shell functions..."
    unset -f workspace
    unset -f _warm_workspaces

    echo -e "\n--- Uninstallation Complete ---"
    echo "To finalize, please restart your shell or run: source ~/.bashrc (or ~/.zshrc)"
    echo "You can now safely delete the installation directory: $INSTALL_DIR"
}

# --- Main Script ---
main() {
    ACTION=install
    for arg in "$@"; do
        case $arg in
            --uninstall)
            ACTION=uninstall
            shift
            ;;
            -y|--yes)
            NON_INTERACTIVE=true
            shift
            ;;
            --help)
            show_help
            exit 0
            ;;
        esac
    done

    if [ "$(id -u)" -eq 0 ]; then abort "This script must not be run as root."; fi

    if [ "$ACTION" = "uninstall" ]; then
        uninstall
    else
        install
    fi
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
