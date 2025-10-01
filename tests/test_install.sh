#!/bin/bash

# Exit on any error
set -e

# --- Test Globals ---

# Source the installer script to make its functions available
# The script is designed to be sourceable withoutrunning its main function
source install.sh

TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
TEST_ENV_DIR="$TEST_DIR/test_env"

# Override HOME to our test environment
export HOME="$TEST_ENV_DIR/home"

# Re-evaluate config variables with the new HOME
CONFIG_DIR="$HOME/.config/workspace"
CONFIG_SCRIPT="$CONFIG_DIR/workspace.sh"
BIN_DIR="$TEST_DIR/../bin"
DEST_LINK="$BIN_DIR/workspace"
SHELL_PROFILE="$HOME/.bashrc"

# --- Test Setup & Teardown ---

setup_test_environment() {
    # Clean up any previous runs
    rm -rf "$TEST_ENV_DIR"
    # Create a clean test environment
    mkdir -p "$HOME"
    rm -rf "$BIN_DIR"
}

teardown_test_environment() {
    rm -rf "$TEST_ENV_DIR"
    rm -rf "$BIN_DIR"
}

# --- Mocks & Spies ---

# Mock `command -v` to assume all dependencies are present for testing install/uninstall
command() {
    if [[ "$1" == "-v" ]]; then
        return 0 # Always return success, "found"
    fi
    # Fallback to the real command for other uses
    /usr/bin/env command "$@"
}

# Mock `git` to prevent actual network calls during `install_oh_my_bash`
git() {
    if [[ "$1" == "clone" ]]; then
        echo "Mock git: Faking clone of $2 to $3"
        mkdir -p "$3"
    fi
}

# Mock `sudo` to avoid asking for a real password
sudo() {
    echo "Sudo mock: Executing '$*'"
    sh -c "$*" # Execute the command without real sudo
}

# --- Assertions ---

assert_file_exists() {
    if [ ! -f "$1" ]; then
        echo "   - FAILED: Expected file '$1' to exist." >&2
        exit 1
    fi
}

assert_dir_exists() {
    if [ ! -d "$1" ]; then
        echo "   - FAILED: Expected directory '$1' to exist." >&2
        exit 1
    fi
}

assert_file_does_not_exist() {
    if [ -f "$1" ]; then
        echo "   - FAILED: Expected file '$1' to not exist." >&2
        exit 1
    fi
}

assert_dir_does_not_exist() {
    if [ -d "$1" ]; then
        echo "   - FAILED: Expected directory '$1' to not exist." >&2
        exit 1
    fi
}

# --- Test Cases ---

test_help_flag_shows_usage() {
    echo " - Running test: test_help_flag_shows_usage"
    local output
    output=$(main --help)

    if ! echo "$output" | grep -q -e "Usage:"; then
        echo "   - FAILED: Expected help output to contain 'Usage:'" >&2
        exit 1
    fi

    if ! echo "$output" | grep -q -e "--uninstall"; then
        echo "   - FAILED: Expected help output to contain '--uninstall'" >&2
        exit 1
    fi

    if ! echo "$output" | grep -q -e "-y, --yes"; then
        echo "   - FAILED: Expected help output to contain '-y, --yes'" >&2
        exit 1
    fi

    echo "   - PASSED"
}

test_install_creates_files_and_configs() {
    echo " - Running test: test_install_creates_files_and_configs"
    setup_test_environment

    # Run the installer in non-interactive mode
    main -y > /dev/null

    assert_dir_exists "$CONFIG_DIR"
    assert_file_exists "$CONFIG_SCRIPT"
    assert_dir_exists "$BIN_DIR"
    assert_file_exists "$DEST_LINK"
    assert_file_exists "$SHELL_PROFILE"

    if ! grep -q -e "source \"$CONFIG_SCRIPT\"" "$SHELL_PROFILE"; then
        echo "   - FAILED: Shell profile was not updated correctly." >&2
        exit 1
    fi

    echo "   - PASSED"
    teardown_test_environment
}

test_uninstall_removes_everything() {
    echo " - Running test: test_uninstall_removes_everything"
    setup_test_environment

    # First, install it non-interactively
    main -y > /dev/null

    # Now, uninstall it non-interactively
    main --uninstall -y > /dev/null

    assert_dir_does_not_exist "$CONFIG_DIR"
    assert_file_does_not_exist "$DEST_LINK"
    assert_dir_does_not_exist "$BIN_DIR"

    if grep -q -e "source \"$CONFIG_SCRIPT\"" "$SHELL_PROFILE"; then
        echo "   - FAILED: Shell profile was not cleaned up." >&2
        exit 1
    fi

    echo "   - PASSED"
    teardown_test_environment
}

# --- Test Runner ---

run_tests() {
    # Ensure teardown is called on script exit
    trap teardown_test_environment EXIT

    echo "Running tests for install.sh..."
    test_help_flag_shows_usage
    test_install_creates_files_and_configs
    test_uninstall_removes_everything
    echo "All tests passed!"
}

# Execute the main function
run_tests
