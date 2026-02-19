# Testing Markspresso

## Running Tests

Execute the integration test suite:

```bash
./test.sh
```

The test suite runs automatically in a temporary directory and cleans up after itself.

## Test Coverage

The test suite verifies:

1. **Module Loading** - Module loads without errors
2. **Site Scaffolding** - `create` command generates proper structure
3. **Configuration** - Config file is valid JSON with required fields
4. **Building** - `build` command generates HTML output
5. **HTML Validity** - Generated HTML has proper structure and content
6. **Front Matter Parsing** - YAML-like front matter is parsed correctly
7. **Draft Handling** - Draft posts are excluded by default
8. **Asset Copying** - Static assets are copied to output
9. **Incremental Builds** - Site can be rebuilt multiple times
10. **Component Architecture** - All refactored components exist

## CI/CD Integration

### GitHub Actions

Add to `.github/workflows/test.yml`:

```yaml
name: Test

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
      - uses: actions/checkout@v3
      
      - name: Install LuCLI
        run: |
          # Install Lucee and LuCLI
          # (Add your specific installation steps)
      
      - name: Run tests
        run: |
          cd /path/to/markspresso
          ./test.sh
```

### GitLab CI

Add to `.gitlab-ci.yml`:

```yaml
test:
  script:
    - cd /path/to/markspresso
    - ./test.sh
```

## Exit Codes

- `0` - All tests passed
- `1` - One or more tests failed

## Test Output

The test script provides colored output:
- ✓ Green checkmarks for passed tests
- ✗ Red X marks for failed tests  
- ℹ Yellow info messages

## Extending Tests

To add a new test:

1. Add a new test section in `test.sh`
2. Use `pass "description"` for successful assertions
3. Use `fail "description"` for failed assertions
4. Use `info "description"` for informational messages

Example:

```bash
echo ""
echo "Test 11: My New Feature"
echo "-----------------------"
# Test logic here
if [ condition ]; then
    pass "Feature works correctly"
else
    fail "Feature failed"
fi
```

## Manual Testing

For manual testing:

```bash
# Create test site
cd /tmp
mkdir my-test-site
cd my-test-site
lucli markspresso create name="My Test"

# Build site
lucli markspresso build clean

# Check output
ls -la public/
cat public/index.html
```

## Bats Testing Framework Primer

For more structured testing, you can use [Bats](https://github.com/bats-core/bats-core) (Bash Automated Testing System).

### Installation

```bash
# macOS
brew install bats-core

# With helper libraries (recommended)
brew install bats-support bats-assert bats-file
```

### Basic Test Structure

Create test files with `.bats` extension:

```bash
# tests/markspresso.bats

setup() {
    # Runs before each test
    TEST_DIR=$(mktemp -d)
    cd "$TEST_DIR"
}

teardown() {
    # Runs after each test
    rm -rf "$TEST_DIR"
}

@test "create generates markspresso.json" {
    run lucli markspresso create --name="Test Site"
    [ "$status" -eq 0 ]
    [ -f "markspresso.json" ]
}

@test "build produces HTML output" {
    lucli markspresso create --name="Test Site"
    run lucli markspresso build
    [ "$status" -eq 0 ]
    [ -d "public" ]
}
```

### Running Tests

```bash
# Run all tests
bats tests/

# Run specific file
bats tests/markspresso.bats

# Run with real-time output
bats -t tests/

# TAP output (for CI)
bats --tap tests/
```

### Key Variables After `run`

The `run` command captures command output:

- `$status` - exit code
- `$output` - full stdout as a single string
- `${lines[@]}` - stdout split into array by newline
- `${lines[0]}` - first line of output

### Debugging Tests

Bats captures stdout/stderr, so use `>&3` to print to terminal:

```bash
@test "debugging example" {
    run lucli markspresso build
    
    # Print debug info to terminal
    echo "status: $status" >&3
    echo "output: $output" >&3
    echo "first line: ${lines[0]}" >&3
    
    [ "$status" -eq 0 ]
}
```

### Common Assertions

```bash
# Exit code
[ "$status" -eq 0 ]         # success
[ "$status" -ne 0 ]         # failure

# Output contains string
[[ "$output" =~ "expected" ]]

# Output equals exactly
[ "$output" = "expected" ]

# File exists
[ -f "path/to/file" ]
[ -d "path/to/dir" ]

# File contains text
grep -q "expected" "file.txt"
```

### Using Helper Libraries

With `bats-assert` and `bats-support`:

```bash
setup() {
    load '/opt/homebrew/lib/bats-support/load'
    load '/opt/homebrew/lib/bats-assert/load'
}

@test "with assertions" {
    run lucli markspresso create
    assert_success
    assert_output --partial "created"
    assert_file_exists "markspresso.json"
}
```
