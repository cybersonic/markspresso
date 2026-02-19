#!/usr/bin/env bats

# Markspresso BATS Tests
# Run with: bats tests/markspresso.bats

load 'test_helper'

# =============================================================================
# Basic Build Tests
# =============================================================================

@test "build command creates output directory" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    dir_exists "public"
}

@test "build command creates index.html" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    file_exists "public/index.html"
}

@test "build outputs correct number of files" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # Should have: index, 2 posts (not draft), docs index + 3 docs = 7 HTML files
    local html_count
    html_count=$(find public -name "*.html" -type f | wc -l | tr -d ' ')
    [ "$html_count" -ge 6 ]
}

# =============================================================================
# Posts Tests
# =============================================================================

@test "posts are built with date-based URLs" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # First post should be at /2025/01/15/first-post.html
    file_exists "public/2025/01/15/first-post.html"
}

@test "second post is built correctly" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_exists "public/2025/02/10/second-post.html"
}

@test "post content contains title" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/2025/01/15/first-post.html" "First Post"
}

@test "post uses post layout with article tag" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/2025/01/15/first-post.html" "<article>"
}

# =============================================================================
# Draft Tests
# =============================================================================

@test "drafts are excluded by default" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # Draft post should NOT exist
    ! file_exists "public/2025/02/12/draft-post.html"
}

@test "drafts are included with drafts=true flag" {
    run lucli markspresso build drafts=true
    [ "$status" -eq 0 ]
    
    # Draft post SHOULD exist now
    file_exists "public/2025/02/12/draft-post.html"
}

# =============================================================================
# Feed Tests
# =============================================================================

@test "RSS feed is generated for posts" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_exists "public/posts/feed.xml"
}

@test "Atom feed is generated for posts" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_exists "public/posts/atom.xml"
}

@test "RSS feed contains valid XML declaration" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/posts/feed.xml" '<?xml version="1.0"'
}

@test "RSS feed contains channel and items" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/posts/feed.xml" "<channel>"
    file_contains "public/posts/feed.xml" "<item>"
}

@test "Atom feed contains valid structure" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/posts/atom.xml" '<feed xmlns="http://www.w3.org/2005/Atom">'
    file_contains "public/posts/atom.xml" "<entry>"
}

@test "feeds contain post titles" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/posts/feed.xml" "First Post"
    file_contains "public/posts/feed.xml" "Second Post"
}

@test "feeds do not contain draft posts" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    ! file_contains "public/posts/feed.xml" "Draft Post"
}

# =============================================================================
# Documentation Tests
# =============================================================================

@test "docs index page is built" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_exists "public/docs/index.html"
}

@test "docs pages have numeric prefixes stripped from URLs" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # 010_getting-started.md should become /docs/getting-started/
    file_exists "public/docs/getting-started/index.html"
}

@test "configuration doc is built" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # 020_configuration.md should become /docs/configuration/
    file_exists "public/docs/configuration/index.html"
}

@test "advanced doc is built" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # 030_advanced.md should become /docs/advanced/
    file_exists "public/docs/advanced/index.html"
}

@test "docs content is correct" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/docs/getting-started/index.html" "Getting Started"
}

# =============================================================================
# Layout and Partial Tests
# =============================================================================

@test "header partial is included" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/index.html" "<header>"
    file_contains "public/index.html" "<nav>"
}

@test "footer partial is included" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/index.html" "<footer>"
    file_contains "public/index.html" "Powered by Markspresso"
}

@test "CSS link is present in output" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/index.html" 'href="/css/style.css"'
}

# =============================================================================
# Assets Tests
# =============================================================================

@test "CSS assets are copied to output" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_exists "public/css/style.css"
}

@test "CSS content is correct" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    file_contains "public/css/style.css" "font-family: sans-serif"
}

# =============================================================================
# Latest Posts Feature Tests
# =============================================================================

@test "homepage contains latest posts section" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # The {{ latest_posts }} token should be replaced with actual posts
    file_contains "public/index.html" "Second Post"
}

@test "latest posts are in correct order (newest first)" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # Get positions of both post titles in the file
    local content
    content=$(cat "public/index.html")
    
    # Second Post (2025-02-10) should appear before First Post (2025-01-15)
    local second_pos first_pos
    second_pos=$(echo "$content" | grep -n "Second Post" | head -1 | cut -d: -f1)
    first_pos=$(echo "$content" | grep -n "First Post" | head -1 | cut -d: -f1)
    
    [ "$second_pos" -lt "$first_pos" ]
}

# =============================================================================
# Search Index Tests
# =============================================================================

@test "Lunr search data is generated" {
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # Search is enabled in config, so the search data JS should exist
    file_exists "public/js/markspresso-search-data.js"
}

# =============================================================================
# Clean Build Tests
# =============================================================================

@test "clean flag removes previous output" {
    # First build
    run lucli markspresso build
    [ "$status" -eq 0 ]
    
    # Create a dummy file in output
    touch "public/dummy-file.txt"
    file_exists "public/dummy-file.txt"
    
    # Build with clean
    run lucli markspresso build clean=true
    [ "$status" -eq 0 ]
    
    # Dummy file should be gone
    ! file_exists "public/dummy-file.txt"
}
