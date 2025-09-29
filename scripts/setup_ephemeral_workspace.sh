#!/bin/bash
# Enhanced script to create, list, and switch ephemeral workspaces.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
WORKSPACE_BASE_DIR="/tmp/dev_sessions"
HISTORY_FILE="$HOME/.workspace_history"
CONFIG_ITEMS=(
  ".gitconfig" ".ssh" ".npmrc" ".yarnrc" ".gcloud" ".config/gcloud"
)

# --- Helper Functions (copied from original) ---
_link_configs() {
    local project_path="$1"
    if [ ! -d "$project_path" ]; then return; fi
    echo "Linking configurations..." >&2
    for item in "${CONFIG_ITEMS[@]}"; do
        local source_path="$HOME/$item"
        local link_path="$project_path/$(basename "$item")"
        if [ -e "$source_path" ] && [ ! -L "$link_path" ]; then
            ln -s "$source_path" "$link_path"
            echo "  - Linked ~/$item" >&2
        fi
done
}

_log_to_history() {
    local git_url="$1"
    local project_path="$2"
    local temp_history
temp_history=$(mktemp)
    echo -e "$git_url\t$project_path" > "$temp_history"
    if [ -f "$HISTORY_FILE" ]; then cat "$HISTORY_FILE" >> "$temp_history"; fi
    awk -F'\t' '!seen[$2]++' "$temp_history" | head -n 10 > "$HISTORY_FILE"
    rm "$temp_history"
}

main() {
    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed. Please install git and try again." >&2
        exit 1
    fi

    mkdir -p "$WORKSPACE_BASE_DIR"

    # --- Sub-command: list (default) ---
    if [[ -z "$1" ]]; then
        if [ ! -f "$HISTORY_FILE" ] || [ ! -s "$HISTORY_FILE" ]; then
            echo "No workspaces in history. Create one with 'workspace <git_repo_url_or_name>'." >&2
            exit 0
        fi
        
        echo "Recent workspaces:" >&2
        local i=1
        local paths=()
        while IFS=$'\t' read -r git_url project_path; do
            local project_name=$(basename "$project_path")
            local status="[☁️]" # Not present locally
            if [ -d "$project_path" ]; then status="[✅]"; fi # Present locally
            printf "  %2d: %s %s\n" "$i" "$status" "$project_name" >&2
            paths[$i]="$project_path"
            i=$((i+1))
done < "$HISTORY_FILE"
        
        echo "Enter a number to switch to a workspace, or any other key to cancel." >&2
        read -p "> " -n 1 -r choice
        echo >&2
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ -n "${paths[$choice]}" ]; then
            echo "${paths[$choice]}" # Output the selected path
        else
            echo "Cancelled." >&2
            exit 0
        fi
        return
    fi

    # --- Sub-command: switch by number ---
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        if [ ! -f "$HISTORY_FILE" ]; then exit 1; fi
        local path_to_enter
        path_to_enter=$(head -n "$1" "$HISTORY_FILE" | tail -n 1 | cut -f 2)
        if [ -z "$path_to_enter" ]; then exit 1; fi
        echo "$path_to_enter" # Output the selected path
        return
    fi

    # --- Sub-command: create ---
    local INPUT="$1"
    local PROJECT_NAME
    local IS_GIT_REPO=false
    if [[ "$INPUT" == *"git@"* || "$INPUT" == *".git"* || "$INPUT" == *"http"* ]]; then
        PROJECT_NAME=$(basename "$INPUT" .git)
        IS_GIT_REPO=true
    else
        PROJECT_NAME="$INPUT"
    fi

    local SANITIZED_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9_-]//g')
    if [ -z "$SANITIZED_NAME" ]; then echo "Error: Project name is invalid." >&2; exit 1; fi
    local PROJECT_PATH="$WORKSPACE_BASE_DIR/$SANITIZED_NAME"

    if [ -d "$PROJECT_PATH" ]; then
        echo "Workspace '$SANITIZED_NAME' already exists." >&2
    else
        if [ "$IS_GIT_REPO" = true ]; then
            echo "Cloning '$INPUT' into '$PROJECT_PATH'..." >&2
            if ! git clone "$INPUT" "$PROJECT_PATH"; then echo "Error: Failed to clone." >&2; exit 1; fi
        else
            echo "Creating new empty workspace '$PROJECT_PATH'..." >&2
            mkdir -p "$PROJECT_PATH"
        fi
    fi

    _link_configs "$PROJECT_PATH"
    
    local GIT_URL="none"
    if [ -d "$PROJECT_PATH/.git" ]; then
        GIT_URL=$(git -C "$PROJECT_PATH" config --get remote.origin.url)

        # NEW: Convert GitHub HTTPS URL to SSH URL for non-interactive cloning.
        if [[ "$GIT_URL" == https://github.com/* ]]; then
            local SSH_URL=$(echo "$GIT_URL" | sed 's|https://github.com/|git@github.com:|')
            echo "Converting clone URL to SSH for background warming: $SSH_URL" >&2
            GIT_URL="$SSH_URL"
        fi
    fi
    _log_to_history "${GIT_URL:-none}" "$PROJECT_PATH"
    
    echo "$PROJECT_PATH" # Output the final path
}

# Route all arguments to the main function
main "$@"
