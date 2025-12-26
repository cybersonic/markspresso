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
