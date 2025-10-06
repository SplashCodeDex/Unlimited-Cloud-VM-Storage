#!/bin/bash

# This script demonstrates the animations available in the project.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/visual_effects.sh"

ANIMATIONS_ENABLED=true

echo "Demonstrating the spinner animation..."
sleep 3 &
spinner $! "Waiting for 2 seconds..."

echo "Demonstrating the progress bar animation..."
progress_bar 15

echo "Animations demonstration complete."
