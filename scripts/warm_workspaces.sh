#!/bin/bash

# This script pre-warms ephemeral workspaces by cloning the most recent projects
# from the history file. It's intended to be run in the background on shell startup.

set -e

HISTORY_FILE="$HOME/.workspace_history"
LOG_FILE="$HOME/.workspace_warming.log"
# Number of recent projects to pre-warm. Let's start with 1.
PROJECT_COUNT=1

echo "--- Starting workspace warming: $(date) --- " > "$LOG_FILE"

if [ ! -f "$HISTORY_FILE" ]; then
    echo "No history file found. Exiting." >> "$LOG_FILE"
    # No history, nothing to do.
    exit 0
fi

# Use a while loop to safely read the tab-separated file
head -n "$PROJECT_COUNT" "$HISTORY_FILE" | while IFS=$'\t' read -r git_url project_path;
    # Perform checks in the main loop process before backgrounding the clone.
    do
        if [ -z "$git_url" ] || [ -z "$project_path" ] || [[ "$git_url" == "none" ]]; then
            # Malformed line or not a git repo, skip.
            continue
        fi

        if [ -d "$project_path" ]; then
            # Workspace already exists, skip.
            continue
        fi

        # Run only the clone operation in a background subshell.
        (
            echo "Pre-warming workspace: $project_path"
            # Clone quietly to not pollute the user's main shell with output
            if git clone --quiet "$git_url" "$project_path"; then
                echo "Pre-warming for '$project_path' complete."
            else
                echo "Pre-warming for '$project_path' failed."
                # If it failed, remove the potentially incomplete directory
                rm -rf "$project_path"
            fi
        ) >> "$LOG_FILE" 2>&1 &
    done

# Wait for all background clone jobs to finish before the script exits.
wait
