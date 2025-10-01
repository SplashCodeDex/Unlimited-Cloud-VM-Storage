#!/bin/bash

# Detects common IDE and build tool cache directories.

PROJECT_PATH="$1"

# Check if we are in a project directory
if [ -z "$PROJECT_PATH" ] || [ ! -d "$PROJECT_PATH" ]; then
    exit 0
fi

DETECTED_DIRS=()

# List of common directories to check for
COMMON_DIRS=(".idea" ".vscode" ".gradle")

for dir in "${COMMON_DIRS[@]}"; do
    if [ -d "$PROJECT_PATH/$dir" ]; then
        DETECTED_DIRS+=("$dir")
    fi
done

# Return the space-separated list of detected directories
echo "${DETECTED_DIRS[@]}"
