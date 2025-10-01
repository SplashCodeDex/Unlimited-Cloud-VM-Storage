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
FIRST_RUN_FLAG="$CONFIG_DIR/.first_run_completed"

# --- Dynamic Homebrew Path ---
# Determine the correct Homebrew path. Prefer the standard system-wide
# location if we can, but fall back to a user-local path if not.
if [[ "$(uname -s)" == "Darwin" ]]; then
    if [[ "$(uname -m)" == "arm64" ]]; then
        HOMEBREW_PREFIX="/opt/homebrew"
    else
        HOMEBREW_PREFIX="/usr/local"
    fi
else
    # On Linux, check if we can write to the default location. If not, use $HOME.
    if [ -w "/home/linuxbrew/.linuxbrew" ] || ( [ ! -d "/home/linuxbrew/.linuxbrew" ] && [ -w "/home" ]); then
        HOMEBREW_PREFIX="/home/linuxbrew/.linuxbrew"
    else
        HOMEBREW_PREFIX="$HOME/.linuxbrew"
    fi
fi
HOMEBREW_BIN="$HOMEBREW_PREFIX/bin"
HOMEBREW_BREW_BIN="$HOMEBREW_BIN/brew"

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
    echo "(1/6) Checking for dependencies..."
    local core_deps=("git" "sqlite3" "rsync")
    local optional_deps=("fzf" "autojump")
    local all_deps=("${core_deps[@]}" "${optional_deps[@]}")
    local missing_deps=()

    # Temporarily add Homebrew to PATH if it exists but isn't in the path yet
    if [ -x "$HOMEBREW_BREW_BIN" ]; then
        export PATH="$HOMEBREW_BIN:$PATH"
    fi

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
        read -p "This script can attempt to install them for you. May I proceed? [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then should_install=true; fi
    fi

    if [ "$should_install" = true ]; then
        install_missing_dependencies "${missing_deps[@]}"
    fi

    # Final check for core dependencies
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

install_missing_dependencies() {
    local missing_deps=("$@")
    local pm_base_cmd=""
    local needs_sudo=true

    # First, check for standard system package managers
    if command -v apt-get &>/dev/null; then pm_base_cmd="apt-get install -y";
    elif command -v yum &>/dev/null; then pm_base_cmd="yum install -y";
    elif command -v dnf &>/dev/null; then pm_base_cmd="dnf install -y";
    elif command -v pacman &>/dev/null; then pm_base_cmd="pacman -S --noconfirm";
    elif command -v apk &>/dev/null; then pm_base_cmd="apk add"; needs_sudo=false;
    elif command -v brew &>/dev/null; then pm_base_cmd="brew install"; needs_sudo=false; fi

    # If no PM, fallback to Homebrew
    if [ -z "$pm_base_cmd" ]; then
        echo "  - No standard package manager found. Attempting to install and use Homebrew."
        if ! command -v brew &>/dev/null; then
            install_homebrew
        fi
        # Re-check for brew after attempting installation
        if command -v brew &>/dev/null; then 
            pm_base_cmd="brew install"; needs_sudo=false;
        fi
    fi

    # Now, try to install with whatever PM we found
    if [ -n "$pm_base_cmd" ]; then
        echo "  - Using '$pm_base_cmd' to install dependencies: ${missing_deps[*]}"
        local install_cmd="$pm_base_cmd ${missing_deps[*]}"
        if [ "$needs_sudo" = true ] && [ "$(id -u)" -ne 0 ] && command -v sudo &>/dev/null; then
            if ! sudo -v; then abort "Sudo privileges are required."; fi
            sudo sh -c "$install_cmd" || echo "  - Warning: Dependency installation failed for some packages."
        else
            sh -c "$install_cmd" || echo "  - Warning: Dependency installation failed for some packages."
        fi
    else
        abort "Could not find a usable package manager and Homebrew installation failed."
    fi
}

install_homebrew() {
    echo "  - Homebrew not found. It will be installed to manage dependencies."
    
    local install_brew=false
    if [ "$NON_INTERACTIVE" = true ]; then
        install_brew=true
    else
        read -p "  - Do you want to install Homebrew now? [Y/n] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then install_brew=true; fi
    fi

    if ! "$install_brew"; then
        abort "Homebrew installation is required to proceed."
    fi

    # Attempt automated installation first. Run as the current user.
    echo "  - Attempting automated Homebrew installation to $HOMEBREW_PREFIX..."
    export NONINTERACTIVE=true
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true

    # Add brew to PATH for this session
    if [ -x "$HOMEBREW_BREW_BIN" ]; then
        eval "$($HOMEBREW_BREW_BIN shellenv)"
        echo "  - Homebrew has been added to your path for this session."
    fi
    
    # If automated install failed, try manual install
    if ! command -v brew &>/dev/null; then
        echo "  - Automated Homebrew installation failed. Attempting manual installation..."
        if ! command -v git &>/dev/null; then
            abort "Manual Homebrew installation requires 'git', which was not found."
        fi
        
        # Clone into the chosen prefix (no sudo needed if it's in $HOME)
        mkdir -p "$HOMEBREW_PREFIX"
        git clone https://github.com/Homebrew/brew.git "$HOMEBREW_PREFIX/Homebrew"
        mkdir -p "$HOMEBREW_BIN"
        ln -sf "$HOMEBREW_PREFIX/Homebrew/bin/brew" "$HOMEBREW_BREW_BIN"

        echo "  - Evaluating Homebrew shell environment..."
        eval "$($HOMEBREW_BREW_BIN shellenv)"
        
        echo "  - Updating Homebrew for the first time..."
        brew update --force --quiet
    fi

    # Final check
    if ! command -v brew &>/dev/null; then
        abort "Homebrew installation failed. Please install it manually and re-run this script."
    fi
}

install_oh_my_shell() {
    local shell_name=$(basename "$SHELL")
    echo -e "\n(2/6) Configuring shell environment..."
    if [ "$shell_name" = "zsh" ] && [ ! -d "$HOME/.oh-my-zsh" ]; then
        echo "  - Oh My Zsh is recommended for the best experience."
        if [ "$NON_INTERACTIVE" = false ]; then
            read -p "  - Do you want to install Oh My Zsh now? [Y/n] " -n 1 -r; echo
            if [[ ! $REPLY =~ ^[Nn]$ ]]; then
                sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
            fi
        else
            sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
        fi
    else
        echo "  - Shell environment checks passed."
    fi
}

setup_shell_config() {
    echo -e "\n(3/6) Creating shell function and configuration..."
    mkdir -p "$CONFIG_DIR"
    cat << EOF > "$CONFIG_SCRIPT"
#!/bin/sh
# Auto-generated by the workspace installer.

# Add Homebrew to your PATH, if it exists
if [ -x "$HOMEBREW_BREW_BIN" ]; then
    eval "\$($HOMEBREW_BREW_BIN shellenv)"
fi

workspace() {
    local executable="$DEST_LINK"
    local output=\$($executable "\$@")
    local exit_code=\$?

    if [ \$exit_code -eq 0 ]; then
        if [[ "\$output" == "__cd__:"* ]]; then
            local dir_to_change_to=\${output#__cd__:}
            if [ -d "\$dir_to_change_to" ]; then
                cd "\$dir_to_change_to"
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
    echo -e "\n(4/6) Updating user's shell profile..."
    local shell_name=$(basename "$SHELL")
    local profile_to_update=""

    if [ "$shell_name" = "bash" ]; then profile_to_update="$HOME/.bashrc"; fi
    if [ "$shell_name" = "zsh" ]; then profile_to_update="$HOME/.zshrc"; fi

    if [ -z "$profile_to_update" ]; then
        echo "Warning: Unsupported shell '$shell_name'. Manual configuration of your shell profile is required." >&2
        return
    fi
    
    touch "$profile_to_update" # Ensure the file exists

    local init_block="# >>> workspace tool initialize >>>\n# This block was automatically added by the workspace installer.\n# To remove, run 'install.sh --uninstall' or simply delete this block.\nif [ -f \"$CONFIG_SCRIPT\" ]; then\n    source \"$CONFIG_SCRIPT\"\nfi\n# <<< workspace tool initialize <<<"

    if ! grep -q "# >>> workspace tool initialize >>>" "$profile_to_update"; then
        echo "  - Adding workspace tool initialization to $profile_to_update..."
        printf "\n%s\n" "$init_block" >> "$profile_to_update"
    else
        echo "  - Workspace tool already initialized in $profile_to_update."
    fi
}

setup_executable() {
    echo -e "\n(5/6) Setting up executable..."
    mkdir -p "$BIN_DIR"
    chmod +x "$SRC_SCRIPT" "$WARM_SCRIPT_PATH"
    ln -sf "$SRC_SCRIPT" "$DEST_LINK"
    echo "  - Linked $SRC_SCRIPT to $DEST_LINK"
}

first_run_experience() {
    if [ -f "$FIRST_RUN_FLAG" ]; then return; fi

    echo -e "\n(6/6) First-time setup..."
    echo "Welcome to the 'workspace' tool! Let's get you configured."

    local default_ws_dir="$HOME/Workspaces"
    local ws_dir=""

    if [ "$NON_INTERACTIVE" = false ]; then
        read -p "Enter the base directory for your workspaces (default: $default_ws_dir): " ws_dir
    fi
    ws_dir=${ws_dir:-$default_ws_dir}

    local config_sh_path="$INSTALL_DIR/scripts/config.sh"
    if [ -f "$config_sh_path" ]; then
        sed -i.bak "s|^export WORKSPACE_BASE_DIR=.*|export WORKSPACE_BASE_DIR=\"$ws_dir\"|" "$config_sh_path"
        rm -f "${config_sh_path}.bak"
        echo "  - Workspace base directory set to: $ws_dir"
    fi

    touch "$FIRST_RUN_FLAG"
    echo "  - First-time setup complete."
}

install() {
    echo "Starting installation of the 'workspace' tool..."
    check_dependencies
    install_oh_my_shell
    setup_shell_config
    update_user_profile
    setup_executable
    first_run_experience

    echo -e "\n--- Installation Complete ---"
    echo "To finish, please restart your shell or run: source $HOME/.bashrc (or the equivalent for your shell)"
}

uninstall() {
    echo "Starting uninstallation of the 'workspace' tool..."

    if [ "$NON_INTERACTIVE" = false ]; then
        read -p "Are you sure you want to uninstall? This will remove the main command and configuration. [y/N] " -n 1 -r; echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then echo "Uninstallation cancelled."; exit 0; fi
    fi

    echo " - Removing shell profile integration..."
    local profile_files=("$HOME/.bashrc" "$HOME/.zshrc" "$HOME/.bash_profile" "$HOME/.profile")

    for profile_file in "${profile_files[@]}"; do
        if [ -f "$profile_file" ]; then
            sed -i.bak '/^# >>> workspace tool initialize >>>/,/^# <<< workspace tool initialize <<</d' "$profile_file"
            rm -f "${profile_file}.bak"
            echo "  - Cleaned up $profile_file."
        fi
    done

    echo " - Removing executable and configuration files..."
    rm -rf "$CONFIG_DIR" "$DEST_LINK"

    echo -e "\n--- Uninstallation Complete ---"
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

    if [ "$(id -u)" -eq 0 ]; then abort "This script must not be run as root."; fi

    install
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
