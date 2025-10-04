#!/bin/bash

# This script installs or uninstalls the 'workspace' command-line tool.
# It uses the system's native package manager to ensure all dependencies are met.

set -e # Exit on any error

# --- Globals -- -
NON_INTERACTIVE=false
PROFILE_UPDATED=""
SYS_PM=""
SUDO_CMD=""

# --- Configuration -- -
INSTALL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
BIN_DIR="$INSTALL_DIR/bin"
SRC_SCRIPT="$INSTALL_DIR/scripts/workspace"
VISUAL_EFFECTS_SCRIPT="$INSTALL_DIR/scripts/visual_effects.sh"
DEST_LINK="$BIN_DIR/workspace"
CONFIG_DIR="$HOME/.config/workspace"
CONFIG_SCRIPT="$CONFIG_DIR/workspace.sh"
WARM_SCRIPT_PATH="$INSTALL_DIR/scripts/warm_workspaces.sh"
FIRST_RUN_FLAG="$CONFIG_DIR/.first_run_completed"
MANIFEST_FILE="$CONFIG_DIR/install-manifest.txt"
NIX_CONFIG_FILE=".idx/dev.nix"

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

is_nix_environment() {
    [ -d "/nix/store" ] && command -v nix-shell &>/dev/null
}

detect_package_manager() {
    if is_nix_environment; then SYS_PM="nix";
    elif command -v apt-get &>/dev/null; then SYS_PM="apt-get";
    elif command -v yum &>/dev/null; then SYS_PM="yum";
    elif command -v dnf &>/dev/null; then SYS_PM="dnf";
    elif command -v pacman &>/dev/null; then SYS_PM="pacman";
    elif command -v apk &>/dev/null; then SYS_PM="apk";
    else
        SYS_PM="unknown"
    fi
}



# --- Nix Configuration ---

build_nix_config() {
    echo "  - Creating new '.idx/dev.nix' from template..."
    mkdir -p ".idx"
    cp "templates/dev.nix.template" "$NIX_CONFIG_FILE"
    echo "  - Successfully created new '$NIX_CONFIG_FILE'."
    echo "profile:$NIX_CONFIG_FILE" >> "$MANIFEST_FILE"
    PROFILE_UPDATED="Nix environment"
}

replace_nix_config() {
    echo "  - '.idx/dev.nix' already exists. Backing it up and replacing it with the template..."
    local backup_file="$NIX_CONFIG_FILE.bak"
    if [ ! -f "$backup_file" ]; then
        cp "$NIX_CONFIG_FILE" "$backup_file"
        echo "profile:$backup_file" >> "$MANIFEST_FILE"
    fi
    cp "templates/dev.nix.template" "$NIX_CONFIG_FILE"
    echo "  - Successfully replaced '$NIX_CONFIG_FILE' with the template."
    PROFILE_UPDATED="Nix environment"
}

handle_nix_config() {
    if [ ! -f "$NIX_CONFIG_FILE" ]; then
        build_nix_config
    else
        replace_nix_config
    fi
}

prompt_for_sudo() {
    if [ -z "$SUDO_CMD" ] && [ "$NON_INTERACTIVE" = false ]; then
        echo "This script needs to install some dependencies using your system's package manager."
        echo "This requires root privileges. Please enter your password if prompted."
        if command -v sudo &>/dev/null; then
            if sudo -v; then
                SUDO_CMD="sudo"
            else
                abort "sudo authentication failed."
            fi
        else
            abort "sudo is not installed. Please install it and run this script again."
        fi
    elif [ -z "$SUDO_CMD" ] && [ "$NON_INTERACTIVE" = true ]; then
        if command -v sudo &>/dev/null; then
            SUDO_CMD="sudo"
        else
            abort "sudo is not installed. Please install it and run this script again."
        fi
    fi
}

# --- Dependency and Shell Management ---

check_dependencies() {
    echo "(1/5) Checking for dependencies..."

    local core_deps=("sqlite3" "rsync" "git" "curl" "ncurses")
    local optional_deps=("fzf" "autojump")
    local missing_deps=()

    for cmd in "${core_deps[@]}" "${optional_deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            missing_deps+=( "$cmd" )
        fi
    done

    if [ ${#missing_deps[@]} -eq 0 ]; then
        echo "  - All dependencies are installed."
        return
    fi

    echo "Warning: The following dependencies are missing: ${missing_deps[*]}"

    if [ "$SYS_PM" = "nix" ]; then
        echo "  - Dependencies have been added to '.idx/dev.nix'. Please restart your shell for them to be available."
        return
    fi

    local should_install=false
    if [ "$NON_INTERACTIVE" = true ]; then
        should_install=true
    else
        echo -n "This script can attempt to install them for you. May I proceed? [Y/n] "
        read -r REPLY
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then should_install=true; fi
    fi

    if [ "$should_install" = true ]; then
        prompt_for_sudo
        install_missing_dependencies "${missing_deps[@]}"
    fi

    # Final check after attempting installation
    local still_missing_core_deps=()
    for cmd in "${core_deps[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            still_missing_core_deps+=( "$cmd" )
        fi
    done

    if [ ${#still_missing_core_deps[@]} -gt 0 ]; then
        abort "The following core dependencies are still missing: ${still_missing_core_deps[*]}. Please install them manually and run this script again."
    fi
}

install_missing_dependencies() {
    local missing_deps=($@)

    if [ "$SYS_PM" = "unknown" ]; then
        abort "Could not detect a supported package manager. Please install the missing dependencies manually: ${missing_deps[*]}"
    fi

    echo "  - Using '$SYS_PM' to install dependencies."

    case $SYS_PM in
        apt-get)
            $SUDO_CMD apt-get update
            $SUDO_CMD apt-get install -y "${missing_deps[@]}"
            ;; 
        yum)
            $SUDO_CMD yum install -y "${missing_deps[@]}"
            ;; 
        dnf)
            $SUDO_CMD dnf install -y "${missing_deps[@]}"
            ;; 
        pacman)
            $SUDO_CMD pacman -Syu --noconfirm "${missing_deps[@]}"
            ;; 
        apk)
            $SUDO_CMD apk update
            $SUDO_CMD apk add "${missing_deps[@]}"
            ;; 
    esac
}



setup_shell_config() {
    echo -e "\n(3/5) Creating shell function and configuration..."
    mkdir -p "$CONFIG_DIR" && echo "dir:$CONFIG_DIR" >> "$MANIFEST_FILE"

    cat << 'EOF' > "$CONFIG_SCRIPT"
#!/bin/sh
# Auto-generated by the workspace installer.

workspace() {
    local executable="__DEST_LINK__"
    local output="$($executable "$@")"
    local exit_code="$?"

    if [ "$exit_code" -eq 0 ]; then
        if [[ "$output" == "__cd__:"* ]]; then
            local dir_to_change_to="${output#__cd__:}"
            if [ -d "$dir_to_change_to" ]; then
                cd "$dir_to_change_to"
            else
                echo "Error: Target directory '$dir_to_change_to' does not exist." >&2
            fi
        else
            echo "$output"
        fi
    else
        echo "$output" >&2
    fi
}

_warm_workspaces() {
    if [ -f "__WARM_SCRIPT_PATH__" ] && [ -x "__WARM_SCRIPT_PATH__" ]; then
        bash "__WARM_SCRIPT_PATH__" &>/dev/null &
    fi
}
EOF
    sed -i "s|__DEST_LINK__|$DEST_LINK|g" "$CONFIG_SCRIPT"
    sed -i "s|__WARM_SCRIPT_PATH__|$WARM_SCRIPT_PATH|g" "$CONFIG_SCRIPT"
    echo "file:$CONFIG_SCRIPT" >> "$MANIFEST_FILE"
    chmod +x "$CONFIG_SCRIPT"
    echo "  - Created $CONFIG_SCRIPT"
}

add_to_profile() {
    local profile_to_update="$1"
    touch "$profile_to_update"

    local init_block
    init_block=$(cat <<EOF
# >>> workspace tool initialize >>>
# This block was automatically added by the workspace installer.
# To remove, run 'install.sh --uninstall' or simply delete this block.
export PATH="$INSTALL_DIR/bin:\$PATH"
if [ -f "$CONFIG_SCRIPT" ]; then
    source "$CONFIG_SCRIPT"
fi
# <<< workspace tool initialize <<<
EOF
)

    if ! grep -q "# >>> workspace tool initialize >>>" "$profile_to_update"; then
        echo "  - Adding workspace tool initialization to $profile_to_update..."
        printf "\n%s\n" "$init_block" >> "$profile_to_update"
        echo "profile:$profile_to_update" >> "$MANIFEST_FILE"
    else
        echo "  - Workspace tool already initialized in $profile_to_update."
    fi
	PROFILE_UPDATED="$profile_to_update"
}

update_standard_shell() {
    echo -e "\n(4/5) Updating user's shell profile..."
    local shell_name=$(basename "$SHELL")
    local profile_to_update=""

    if [ "$shell_name" = "bash" ]; then profile_to_update="$HOME/.bashrc"; fi
    if [ "$shell_name" = "zsh" ]; then profile_to_update="$HOME/.zshrc"; fi

    if [ -z "$profile_to_update" ]; then
        echo "Warning: Unsupported shell '$shell_name'."
        echo "Please manually add the following lines to your shell's profile file (e.g., ~/.profile, ~/.config/fish/config.fish):"
        echo "    export PATH=\"$INSTALL_DIR/bin:\$PATH\""
        echo "    if [ -f \"$CONFIG_SCRIPT\" ]; then source \"$CONFIG_SCRIPT\"; fi"
        export PATH="$INSTALL_DIR/bin:$PATH"
        return
    fi

    add_to_profile "$profile_to_update"
}

setup_executable() {
    echo -e "\n(5/5) Setting up executable..."
    mkdir -p "$BIN_DIR" && echo "dir:$BIN_DIR" >> "$MANIFEST_FILE"
    chmod +x "$SRC_SCRIPT" "$WARM_SCRIPT_PATH" "$VISUAL_EFFECTS_SCRIPT"
    if [ -d "$INSTALL_DIR/scripts/detectors" ]; then
        chmod +x "$INSTALL_DIR/scripts/detectors/"*.sh
    fi
    ln -sf "$SRC_SCRIPT" "$DEST_LINK"
    echo "file:$DEST_LINK" >> "$MANIFEST_FILE"
    echo "  - Linked $SRC_SCRIPT to $DEST_LINK"
}

first_run_experience() {
    if [ -f "$FIRST_RUN_FLAG" ]; then return; fi

    echo -e "\n--- First-time setup ---"
    echo "Welcome to the 'workspace' tool! Let's get you configured."

    local default_ws_dir="$HOME/Workspaces"
    local ws_dir=""

    if [ "$NON_INTERACTIVE" = false ]; then
        echo -n "Enter the base directory for your workspaces (default: $default_ws_dir): "
        read -r ws_dir
    fi
    ws_dir=${ws_dir:-$default_ws_dir}

    local config_sh_path="$INSTALL_DIR/scripts/config.sh"
    if [ -f "$config_sh_path" ]; then
        sed -i.bak "s|^export WORKSPACE_BASE_DIR=.*|export WORKSPACE_BASE_DIR=\"$ws_dir\"|" "$config_sh_path" || abort "Failed to set workspace base directory"
        rm -f "${config_sh_path}.bak"
        echo "  - Workspace base directory set to: $ws_dir"
    fi

    touch "$FIRST_RUN_FLAG"
    echo "file:$FIRST_RUN_FLAG" >> "$MANIFEST_FILE"
    echo "  - First-time setup complete."
}

install() {
    rm -f "$MANIFEST_FILE"
    mkdir -p "$CONFIG_DIR"
    touch "$MANIFEST_FILE"

    echo "Starting installation of the 'workspace' tool..."

    detect_package_manager
    if [ "$SYS_PM" = "nix" ]; then
        handle_nix_config
    fi

    check_dependencies
    setup_shell_config
    if [ "$SYS_PM" != "nix" ]; then
        update_standard_shell
        if [ -n "$PROFILE_UPDATED" ]; then
            source "$PROFILE_UPDATED"
        fi
    fi
    export PATH="$BIN_DIR:$PATH"
    setup_executable
    first_run_experience

    echo -e "\n--- Verifying Installation ---"
    if command -v workspace &>/dev/null && workspace doctor --silent; then
        echo "✅ Verification successful!"
    else
        echo "⚠️ Verification failed. Please run 'workspace doctor' for more details."
    fi

    echo -e "\n--- Installation Complete ---"
    echo "To finish, please restart your shell or run: source $PROFILE_UPDATED"
}

standard_uninstall() {
    echo "Warning: Installation manifest not found. Proceeding with a standard uninstall."

    if is_nix_environment; then
        echo "Warning: Could not find backup for .idx/dev.nix. Please restore it manually."
    fi

    rm -rf "$CONFIG_DIR" "$DEST_LINK"
    local profile_files=("$HOME/.bashrc" "$HOME/.zshrc")
    for profile_file in "${profile_files[@]}"; do
        if [ -f "$profile_file" ]; then
            sed -i.bak '/^# >>> workspace tool initialize >>>/,/# <<< workspace tool initialize <<</d' "$profile_file" >/dev/null 2>&1 || true
            rm -f "${profile_file}.bak"
        fi
    done
}

uninstall() {
    echo "Starting uninstallation of the 'workspace' tool..."

    if [ "$NON_INTERACTIVE" = false ]; then
        echo -n "Are you sure you want to uninstall? This will remove everything created by the installer. [y/N] "
        read -r REPLY
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then echo "Uninstallation cancelled."; exit 0; fi
    fi

    if [ ! -f "$MANIFEST_FILE" ]; then
        standard_uninstall
    else
        echo " - Reading installation manifest..."
        tac "$MANIFEST_FILE" | while IFS= read -r line; do
            local type="${line%%:*}"
            local path="${line#*:}"

            case "$type" in
                profile)
                    if [ "$path" = "$NIX_CONFIG_FILE.bak" ]; then
                        echo "   - Restoring backup of .idx/dev.nix..."
                        mv "$path" "$NIX_CONFIG_FILE"
                    elif [ "$path" = "$NIX_CONFIG_FILE" ]; then
                        # This is the case where the user's original dev.nix was replaced
                        # but the backup was not recorded in the manifest. We can't do anything here.
                        echo "Warning: Could not find backup for .idx/dev.nix. Please restore it manually."
                    else
                        echo "   - Removing shell profile entry from $path..."
                        if [ -f "$path" ]; then
                            sed -i.bak '/^# >>> workspace tool initialize >>>/,/# <<< workspace tool initialize <<</d' "$path" >/dev/null 2>&1 || true
                            rm -f "${path}.bak"
                        fi
                    fi
                    ;; 
                file)
                    echo "   - Removing file: $path..."
                    rm -f "$path"
                    ;; 
                dir)
                    if [ -d "$path" ] && [ -z "$(ls -A "$path")" ]; then
                        echo "   - Removing empty directory: $path..."
                        rmdir "$path"
                    elif [ -d "$path" ]; then
                         echo "   - Directory not empty, skipping: $path..."
                    fi
                    ;; 
            esac
        done
        rm -f "$MANIFEST_FILE"
        if [ -d "$CONFIG_DIR" ] && [ -z "$(ls -A "$CONFIG_DIR")" ]; then
            rmdir "$CONFIG_DIR"
        fi
    fi

    echo -e "\n--- Uninstallation Complete ---"
    echo "Note: Dependencies installed by the system package manager were not removed."
    echo "You can now safely delete the installation directory: $INSTALL_DIR"
}


# --- Main Script ---
main() {
    for arg in "$@"; do
        case $arg in
            --uninstall) uninstall; exit 0 ;; 
            -y|--yes) NON_INTERACTIVE=true; shift ;; 
            --help) show_help; exit 0 ;; 
        esac
    done

    install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi