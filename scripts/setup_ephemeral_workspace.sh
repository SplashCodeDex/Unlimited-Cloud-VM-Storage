#!/bin/bash
# Enhanced script to create, list, and switch ephemeral workspaces.

set -e # Exit immediately if a command exits with a non-zero status.

# --- Configuration ---
WORKSPACE_BASE_DIR="/tmp/dev_sessions"
DB_FILE="$HOME/.workspace_history.db"
CONFIG_ITEMS=(
  ".gitconfig" ".ssh" ".npmrc" ".yarnrc" ".gcloud" ".config/gcloud"
)

# --- Helper Functions ---
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

init_database() {
    if ! command -v sqlite3 &> /dev/null; then
        echo "Error: sqlite3 is not installed. Please install sqlite3 and try again." >&2
        exit 1
    fi

    if [ ! -f "$DB_FILE" ]; then
        echo "Creating new workspace history database at $DB_FILE..." >&2
        sqlite3 "$DB_FILE" "CREATE TABLE workspaces (
            path TEXT PRIMARY KEY,
            git_url TEXT,
            last_access INTEGER,
            frequency INTEGER DEFAULT 1
        );"
    fi
}

_update_history() {
    local git_url="$1"
    local project_path="$2"
    local current_time=$(date +%s)

    # Check if the workspace already exists in the database
    local existing_entry=$(sqlite3 "$DB_FILE" "SELECT path FROM workspaces WHERE path='$project_path';")

    if [ -z "$existing_entry" ]; then
        # Insert a new entry
        sqlite3 "$DB_FILE" "INSERT INTO workspaces (path, git_url, last_access, frequency) VALUES ('$project_path', '$git_url', $current_time, 1);"
    else
        # Update the existing entry
        sqlite3 "$DB_FILE" "UPDATE workspaces SET last_access=$current_time, frequency=frequency+1 WHERE path='$project_path';"
    fi
}

main() {
    init_database

    if ! command -v git &> /dev/null; then
        echo "Error: git is not installed. Please install git and try again." >&2
        exit 1
    fi

    mkdir -p "$WORKSPACE_BASE_DIR"

    # --- Sub-command: list (default) ---
    if [[ -z "$1" ]]; then
        if [ ! -f "$DB_FILE" ]; then
            echo "No workspaces in history. Create one with 'workspace <git_repo_url_or_name>'." >&2
            exit 0
        fi
        
        echo "Recent workspaces (ranked by frecency):" >&2
        local i=1
        local paths=()
        # Frecency formula: frequency * (now - last_access)
        # A higher score is better. We will order by score DESC.
        # We will use a simple formula for now: frequency / (now - last_access)
        # To avoid division by zero, we add 1 to the denominator.
        # A better approach would be to use a more sophisticated formula.
        while IFS='|' read -r path; do
            local project_name=$(basename "$path")
            local status="[☁️]" # Not present locally
            if [ -d "$path" ]; then status="[✅]"; fi # Present locally
            printf "  %2d: %s %s\n" "$i" "$status" "$project_name" >&2
            paths[$i]="$path"
            i=$((i+1))
        done < <(sqlite3 -separator '|' "$DB_FILE" "SELECT path FROM workspaces ORDER BY (frequency / (strftime('%s','now') - last_access + 1)) DESC, last_access DESC LIMIT 10;")

        echo "Enter a number to switch to a workspace, or any other key to cancel." >&2
        read -p "> " -n 1 -r choice
        echo >&2
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ -n "${paths[$choice]}" ]; then
            _update_history "" "${paths[$choice]}" # Update history on selection
            echo "${paths[$choice]}" # Output the selected path
        else
            echo "Cancelled." >&2
            exit 0
        fi
        return
    fi

    # --- Sub-command: switch by number ---
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        if [ ! -f "$DB_FILE" ]; then exit 1; fi
        local path_to_enter
        path_to_enter=$(sqlite3 "$DB_FILE" "SELECT path FROM workspaces ORDER BY (frequency / (strftime('%s','now') - last_access + 1)) DESC, last_access DESC LIMIT 1 OFFSET $(($1 - 1));")
        if [ -z "$path_to_enter" ]; then exit 1; fi
        _update_history "" "$path_to_enter" # Update history on selection
        echo "$path_to_enter" # Output the selected path
        return
    fi

    # --- Sub-command: create ---
    local INPUT="$1"
    local PROJECT_NAME
    local IS_GIT_REPO=false
    if [[ "$INPUT" == *git@* || "$INPUT" == *.git* || "$INPUT" == *http* ]]; then
        PROJECT_NAME=$(basename "$INPUT" .git)
        IS_GIT_REPO=true
    else
        PROJECT_NAME="$INPUT"
    fi

    local SANITIZED_NAME=$(echo "$PROJECT_NAME" | sed 's/[^a-zA-Z0-9_-]//g')
    if [ -z "$SANITIZED_NAME" ]; then echo "Error: Project name is invalid." >&2; exit 1; fi
    local PROJECT_PATH="$WORKSPACE_BASE_DIR/$SANITIZED_NAME"

    if [ -d "$PROJECT_PATH" ] && [ "$(ls -A "$PROJECT_PATH")" ]; then
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
    _update_history "$GIT_URL" "$PROJECT_PATH"
    
    echo "$PROJECT_PATH" # Output the final path
}

# Route all arguments to the main function
main "$@"