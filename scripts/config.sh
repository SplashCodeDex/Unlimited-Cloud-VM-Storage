#!/bin/bash

# --- Shared Configuration for Ephemeral Workspace Scripts ---

# Core paths
export WORKSPACE_BASE_DIR="$HOME/workspaces"
export EPHEMERAL_CACHE_DIR="/tmp/dev_cache"

# Database file for workspace history
export DB_FILE="$HOME/.workspace_history.db"

# Main configuration file for dotfile symlinks
# This path should be relative to the project root.
export WORKSPACE_CONFIGS_FILE=".workspace_configs"

# Log file for the warming script
export WARMING_LOG_FILE="$HOME/.workspace_warming.log"

# Number of projects to pre-warm in the background
export WARMING_PROJECT_COUNT=1

# Threshold for detecting large, untracked directories (in KB)
export LARGE_DIR_THRESHOLD_KB=51200
