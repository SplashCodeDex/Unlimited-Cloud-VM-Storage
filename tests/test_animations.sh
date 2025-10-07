#!/bin/bash

# This script demonstrates the animations available in the project.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/visual_effects.sh"

ANIMATIONS_ENABLED=true

echo "Demonstrating the spinner animation..."
sleep 3 &
spinner $! "Waiting for 2 seconds..."

echo "Demonstrating the progress bar animation..."
messages=(
    "'reify:es-toolkit: http fetch GET 200 https://registry.npmjs.org/es-toolkit'"
    "'reify:zod: http fetch GET 200 https://registry.npmjs.org/zod'"
    "'reify:ink: http fetch GET 200 https://registry.npmjs.org/ink'"
    "'reify:fzf: http fetch GET 200 https://registry.npmjs.org/fzf'"
    "'reify:glob: http fetch GET 200 https://registry.npmjs.org/glob'"
)
progress_bar 5 "" "${messages[@]}"

echo "Animations demonstration complete."
