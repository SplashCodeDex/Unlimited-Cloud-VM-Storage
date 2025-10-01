#!/bin/bash

# --- Test Setup ---

# Exit on any error
set -e

# Source the installer script to make its functions available
# We will redirect stdout and stderr to /dev/null to avoid cluttering the test output
source install.sh >/dev/null 2>&1

# --- Test Cases ---

# Test that the script exits if run as root
test_must_not_run_as_root() {
    echo " - Running test: test_must_not_run_as_root"
    if [ "$(id -u)" -eq 0 ]; then
        # We are root, so we expect the script to fail
        if ! ./install.sh >/dev/null 2>&1; then
            echo "   - PASSED"
        else
            echo "   - FAILED"
            exit 1
        fi
    else
        # We are not root, so we expect the script to succeed
        if ./install.sh >/dev/null 2>&1; then
            echo "   - PASSED"
        else
            echo "   - FAILED"
            exit 1
        fi
    fi
}

# --- Test Runner ---

main() {
    echo "Running tests for install.sh..."
    test_must_not_run_as_root
    echo "All tests passed!"
}

main
