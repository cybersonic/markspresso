#!/usr/bin/env bash

# Test helper for Markspresso BATS tests

# Get the directory containing this script
TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$TESTS_DIR")"
SAMPLE_BLOG="$TESTS_DIR/artefacts/sample-blog"

# Temporary directory for test outputs
export TEST_OUTPUT_DIR=""

# Setup function - called before each test
setup() {
    # Create a temporary directory for test outputs
    TEST_OUTPUT_DIR="$(mktemp -d)"
    
    # Copy sample blog to temp directory for isolation
    cp -r "$SAMPLE_BLOG" "$TEST_OUTPUT_DIR/site"
    
    # Change to the test site directory
    cd "$TEST_OUTPUT_DIR/site"
}

# Teardown function - called after each test
teardown() {
    # Clean up temporary directory
    if [[ -n "$TEST_OUTPUT_DIR" && -d "$TEST_OUTPUT_DIR" ]]; then
        rm -rf "$TEST_OUTPUT_DIR"
    fi
}

# Helper: Run markspresso build
run_build() {
    local extra_args="${1:-}"
    run lucli markspresso build $extra_args
}

# Helper: Check if file exists
file_exists() {
    [[ -f "$1" ]]
}

# Helper: Check if directory exists
dir_exists() {
    [[ -d "$1" ]]
}

# Helper: Check if file contains string
file_contains() {
    local file="$1"
    local pattern="$2"
    grep -q "$pattern" "$file"
}

# Helper: Get file content
file_content() {
    cat "$1"
}

# Helper: Count files matching pattern
count_files() {
    local dir="$1"
    local pattern="$2"
    find "$dir" -name "$pattern" -type f 2>/dev/null | wc -l | tr -d ' '
}
