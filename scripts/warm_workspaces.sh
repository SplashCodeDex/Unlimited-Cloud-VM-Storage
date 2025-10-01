#!/bin/bash

# This script "warms" the ephemeral workspaces by ensuring that their Git
# repositories are up-to-date. This makes subsequent access faster.

# Source the shared configuration to get the database file path
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Exit if the database file doesn't exist
if [ ! -f "$DB_FILE" ]; then exit 0; fi

# Function to warm a single workspace
warm_workspace() {
    local path="$1"
    local git_url="$2"
    if [ -d "$path/.git" ] && [[ "$git_url" == git@* ]]; then
        echo "Warming $path..."
        # Use a timeout to prevent it from hanging indefinitely
        timeout 30s git -C "$path" fetch --all -p &>/dev/null || echo "  - Timed out or failed to warm $path"
    fi
}

# Read all git-based workspaces from the database and warm them in parallel
while IFS='|' read -r path git_url; do
    warm_workspace "$path" "$git_url" &
    # Limit parallel jobs to a reasonable number to avoid overwhelming the system
    if (("$(jobs -p | wc -l)" >= 4)); then wait -n; fi
done < <(sqlite3 -separator '|' "$DB_FILE" "SELECT path, git_url FROM workspaces WHERE git_url != 'none';")

# Wait for all background jobs to complete
wait

# echo "Workspace warming complete."
