#!/bin/bash
set -e

# Define the path to the visual effects script
SCRIPT_DIR="/workspaces/Unlimited-Cloud-VM-Storage/scripts"
VISUAL_EFFECTS_SCRIPT="$SCRIPT_DIR/visual_effects.sh"

# Source the visual effects script
source "$VISUAL_EFFECTS_SCRIPT"

# Ensure animations are enabled for this test
ANIMATIONS_ENABLED=true

echo "--- Testing Spinner Animation ---"

# Run a background process for the spinner to monitor
sleep 5 &
SPINNER_PID=$!

# Call the spinner function
spinner $SPINNER_PID "Performing a test operation"

echo "--- Spinner Test Complete ---"

echo "--- Testing Progress Bar Animation ---"

# Call the progress_bar function
progress_bar 3 "Simulating a task"

echo "--- Progress Bar Test Complete ---"

echo "--- Testing Dots Animation ---"

# Call the dots function
dots "Loading"

echo "--- Dots Test Complete ---"

# Check tput status
echo "--- tput status ---"
if command -v tput &>/dev/null; then
    echo "tput is installed."
    echo "tput colors: $(tput colors)"
    echo "tput sgr0: $(tput sgr0)"
else
    echo "tput is NOT installed."
fi
echo "-------------------"
