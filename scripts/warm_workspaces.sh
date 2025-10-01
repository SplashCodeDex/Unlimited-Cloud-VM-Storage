#!/bin/bash

# This script pre-warms ephemeral workspaces by cloning the most frecently used projects
# from the SQLite database. It's intended to be run in the background on shell startup.

set -e

# --- Configuration ---
# Get the directory of the script itself to reliably source the config
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# --- Main Logic ---
echo "--- Starting workspace warming: $(date) --- " > "$WARMING_LOG_FILE"

# Check for dependencies
if ! command -v sqlite3 &> /dev/null; then
    echo "Error: sqlite3 is not installed. Cannot warm workspaces." >> "$WARMING_LOG_FILE"
    exit 1
fi

if [ ! -f "$DB_FILE" ]; then
    echo "No history database found at $DB_FILE. Exiting." >> "$WARMING_LOG_FILE"
    exit 0
fi

# Query the database for the top N frecent workspaces with valid git URLs
sqlite3 -separator '|' "$DB_FILE" \
    "SELECT git_url, path FROM workspaces WHERE git_url != 'none' ORDER BY (frequency / (strftime('%s','now') - last_access + 1)) DESC, last_access DESC LIMIT $WARMING_PROJECT_COUNT;" | \
while IFS='|' read -r git_url project_path; do
    # Perform checks before backgrounding the clone.
    if [ -z "$git_url" ] || [ -z "$project_path" ]; then
        echo "Skipping malformed entry from database..." >> "$WARMING_LOG_FILE"
        continue
    fi

    if [ -d "$project_path" ]; then
        echo "Workspace at '$project_path' already exists. Skipping warm-up." >> "$WARMING_LOG_FILE"
        continue
    fi

    # Run the clone operation in a background subshell for concurrency.
    (
        echo "Pre-warming workspace: $project_path from $git_url"
        # Clone quietly to not pollute the user's main shell with output
        if git clone --quiet "$git_url" "$project_path"; then
            echo "Pre-warming for '$project_path' complete."
        else
            echo "Pre-warming for '$project_path' failed."
            # If it failed, remove the potentially incomplete directory
            rm -rf "$project_path"
        fi
    ) >> "$WARMING_LOG_FILE" 2>&1 &

done

# Wait for all background clone jobs to finish before the script exits.
wait

echo "--- Workspace warming finished: $(date) --- " >> "$WARMING_LOG_FILE"
