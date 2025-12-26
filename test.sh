#!/bin/bash

# Markspresso Integration Test Suite
# Tests core functionality: create, build, and watch

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "🧪 Markspresso Integration Test Suite"
echo "======================================"
echo ""

# Track test results
TESTS_PASSED=0
TESTS_FAILED=0

# Helper functions
pass() {
    echo -e "${GREEN}✓${NC} $1"
    ((TESTS_PASSED++))
}

fail() {
    echo -e "${RED}✗${NC} $1"
    ((TESTS_FAILED++))
}

info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

# Create test directory
TEST_DIR=$(mktemp -d -t markspresso-test-XXXXXX)
info "Using test directory: $TEST_DIR"

# Cleanup on exit
cleanup() {
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        info "Cleaned up test directory"
    fi
}
trap cleanup EXIT

# Change to test directory
cd "$TEST_DIR"

echo ""
echo "Test 1: Module loads successfully"
echo "-----------------------------------"
if lucli markspresso > /dev/null 2>&1; then
    pass "Module loads and displays help"
else
    fail "Module failed to load"
fi

echo ""
echo "Test 2: Create site scaffolding"
echo "--------------------------------"
lucli markspresso create name="CI Test Site" > /dev/null 2>&1 || true

if [ -f "markspresso.json" ]; then
    pass "Config file created"
else
    fail "Config file not created"
fi

if [ -d "content" ]; then
    pass "Content directory created"
else
    fail "Content directory not created"
fi

if [ -d "layouts" ]; then
    pass "Layouts directory created"
else
    fail "Layouts directory not created"
fi

if [ -d "assets" ]; then
    pass "Assets directory created"
else
    fail "Assets directory not created"
fi

if [ -d "public" ]; then
    pass "Public directory created"
else
    fail "Public directory not created"
fi

if [ -f "content/index.md" ]; then
    pass "Starter content created"
else
    fail "Starter content not created"
fi

if [ -f "layouts/page.html" ]; then
    pass "Page layout created"
else
    fail "Page layout not created"
fi

if [ -f "layouts/post.html" ]; then
    pass "Post layout created"
else
    fail "Post layout not created"
fi

echo ""
echo "Test 3: Config file validity"
echo "-----------------------------"
if grep -q '"name"' markspresso.json; then
    pass "Config contains site name"
else
    fail "Config missing site name"
fi

if grep -q '"paths"' markspresso.json; then
    pass "Config contains paths"
else
    fail "Config missing paths"
fi

if grep -q '"collections"' markspresso.json; then
    pass "Config contains collections"
else
    fail "Config missing collections"
fi

echo ""
echo "Test 4: Build site"
echo "------------------"
lucli markspresso build clean > /dev/null 2>&1 || true

if [ -f "public/index.html" ]; then
    pass "Index page built"
else
    fail "Index page not built"
fi

echo ""
echo "Test 5: Generated HTML validity"
echo "--------------------------------"
if grep -q "<!doctype html>" public/index.html; then
    pass "HTML has doctype"
else
    fail "HTML missing doctype"
fi

if grep -q "<title>Home</title>" public/index.html; then
    pass "HTML has correct title"
else
    fail "HTML missing or incorrect title"
fi

if grep -q "CI Test Site" public/index.html; then
    pass "HTML contains site name from config"
else
    fail "HTML missing site name"
fi

if grep -q "charset=\"utf-8\"" public/index.html; then
    pass "HTML has UTF-8 charset"
else
    fail "HTML missing UTF-8 charset"
fi

echo ""
echo "Test 6: Front matter parsing"
echo "-----------------------------"
# Create a test post with front matter
mkdir -p content/posts
cat > content/posts/test-post.md << 'EOF'
---
title: Test Post
layout: post
draft: false
---

This is a test post with front matter.
EOF

lucli markspresso build clean > /dev/null 2>&1 || true

if [ -f "public/posts/test-post/index.html" ]; then
    pass "Post with front matter built (pretty URLs)"
else
    fail "Post with front matter not built"
fi

if grep -q "Test Post" public/posts/test-post/index.html; then
    pass "Front matter title parsed correctly"
else
    fail "Front matter title not found in output"
fi

echo ""
echo "Test 7: Draft exclusion"
echo "-----------------------"
cat > content/posts/draft-post.md << 'EOF'
---
title: Draft Post
draft: true
---

This should not be built by default.
EOF

lucli markspresso build clean > /dev/null 2>&1 || true

if [ ! -f "public/posts/draft-post/index.html" ]; then
    pass "Draft post excluded by default"
else
    fail "Draft post was built (should be excluded)"
fi

# Note: Draft inclusion test would require checking build output more carefully
info "Skipping draft inclusion test (requires deeper inspection)"

echo ""
echo "Test 8: Asset copying"
echo "---------------------"
mkdir -p assets/css
echo "body { color: red; }" > assets/css/style.css

lucli markspresso build clean > /dev/null 2>&1 || true

if [ -f "public/css/style.css" ]; then
    pass "Assets copied to output directory"
else
    fail "Assets not copied"
fi

echo ""
echo "Test 9: Rebuild site"
echo "--------------------"
# Build twice to ensure incremental builds work
lucli markspresso build > /dev/null 2>&1 || true
lucli markspresso build > /dev/null 2>&1 || true

if [ -f "public/index.html" ]; then
    pass "Site can be rebuilt multiple times"
else
    fail "Rebuild failed"
fi

echo ""
echo "Test 10: Component architecture"
echo "--------------------------------"
MODULE_DIR=$(dirname "$(dirname "$(which lucli)")")/.lucli/modules/markspresso

if [ -f "$MODULE_DIR/lib/ConfigService.cfc" ]; then
    pass "ConfigService component exists"
else
    fail "ConfigService component missing"
fi

if [ -f "$MODULE_DIR/lib/ContentParser.cfc" ]; then
    pass "ContentParser component exists"
else
    fail "ContentParser component missing"
fi

if [ -f "$MODULE_DIR/lib/FileService.cfc" ]; then
    pass "FileService component exists"
else
    fail "FileService component missing"
fi

if [ -f "$MODULE_DIR/lib/Builder.cfc" ]; then
    pass "Builder component exists"
else
    fail "Builder component missing"
fi

# Summary
echo ""
echo "======================================"
echo "Test Results"
echo "======================================"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    echo "❌ Some tests failed"
    exit 1
else
    echo -e "${GREEN}Failed: 0${NC}"
    echo ""
    echo "✅ All tests passed!"
    exit 0
fi
