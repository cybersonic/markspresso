#!/usr/bin/env bash

# markspresso Release Management Script
# Uses module.json as the version source of truth.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
MODULE_JSON="$PROJECT_ROOT/module.json"
BUILD_SCRIPT="$PROJECT_ROOT/devops/build-binary.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
  echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
  echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
  echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
  echo -e "${RED}❌ $1${NC}"
}

die() {
  log_error "$1"
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

ensure_module_json() {
  [[ -f "$MODULE_JSON" ]] || die "module.json not found at $MODULE_JSON"
}

get_current_version() {
  ensure_module_json
  jq -r '.version // empty' "$MODULE_JSON"
}

set_version() {
  local new_version="$1"
  local tmp_file
  tmp_file="$(mktemp)"
  jq --arg version "$new_version" '.version = $version' "$MODULE_JSON" > "$tmp_file"
  mv "$tmp_file" "$MODULE_JSON"
}

default_lucli_dir() {
  if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
    echo "$GITHUB_WORKSPACE/LuCLI"
  else
    echo "$(cd "$PROJECT_ROOT/.." && pwd)/LuCLI"
  fi
}

resolve_binary_path() {
  if [[ -n "${BINARY_PATH:-}" ]]; then
    echo "$BINARY_PATH"
    return
  fi
  local lucli_dir="${LUCLI_DIR:-$(default_lucli_dir)}"
  echo "$lucli_dir/target/markspresso"
}

is_semver_xyz() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]
}

is_valid_version_string() {
  [[ "$1" =~ ^[0-9]+\.[0-9]+\.[0-9]+([.-][0-9A-Za-z.-]+)?$ ]]
}

bump_version() {
  local bump_type="$1"
  local current_version major minor patch new_version
  current_version="$(get_current_version)"

  [[ -n "$current_version" ]] || die "module.json is missing a non-empty version field"
  if ! is_semver_xyz "$current_version"; then
    die "Current version '$current_version' is not X.Y.Z; use 'set-version' for non-standard versions"
  fi

  IFS='.' read -r major minor patch <<< "$current_version"

  case "$bump_type" in
    major)
      new_version="$((major + 1)).0.0"
      ;;
    minor)
      new_version="${major}.$((minor + 1)).0"
      ;;
    patch)
      new_version="${major}.${minor}.$((patch + 1))"
      ;;
    *)
      die "Invalid bump type '$bump_type'. Use: major, minor, or patch"
      ;;
  esac

  set_version "$new_version"
  log_success "Version bumped from $current_version to $new_version"
}

set_version_explicit() {
  local requested_version="$1"
  local current_version
  current_version="$(get_current_version)"

  if ! is_valid_version_string "$requested_version"; then
    die "Invalid version '$requested_version'. Expected X.Y.Z or X.Y.Z-suffix"
  fi

  set_version "$requested_version"
  log_success "Version changed from $current_version to $requested_version"
}

ensure_clean_git() {
  local status_output
  status_output="$(git -C "$PROJECT_ROOT" status --porcelain)"
  [[ -z "$status_output" ]] || die "Working tree is not clean. Commit or stash changes first."
}

tag_exists_local() {
  local tag="$1"
  git -C "$PROJECT_ROOT" rev-parse -q --verify "refs/tags/$tag" >/dev/null 2>&1
}

tag_exists_remote() {
  local tag="$1"
  git -C "$PROJECT_ROOT" ls-remote --exit-code --tags origin "refs/tags/$tag" >/dev/null 2>&1
}

ensure_tag_available() {
  local tag="$1"
  if tag_exists_local "$tag"; then
    die "Tag $tag already exists locally"
  fi
  if tag_exists_remote "$tag"; then
    die "Tag $tag already exists on origin"
  fi
}

build_binary() {
  [[ -f "$BUILD_SCRIPT" ]] || die "Build script not found: $BUILD_SCRIPT"

  log_info "Building binary via devops/build-binary.sh"
  if [[ -n "${LUCLI_DIR:-}" ]]; then
    MARKSPRESSO_DIR="$PROJECT_ROOT" LUCLI_DIR="$LUCLI_DIR" bash "$BUILD_SCRIPT"
  else
    MARKSPRESSO_DIR="$PROJECT_ROOT" bash "$BUILD_SCRIPT"
  fi

  local binary_path
  binary_path="$(resolve_binary_path)"
  [[ -f "$binary_path" ]] || die "Expected binary not found after build: $binary_path"
  log_success "Binary created at $binary_path"
}

create_and_push_tag() {
  local tag="$1"
  git -C "$PROJECT_ROOT" tag -a "$tag" -m "Release $tag"
  git -C "$PROJECT_ROOT" push origin "$tag"
  log_success "Created and pushed tag $tag"
}

create_github_release() {
  local tag="$1"
  local binary_path="$2"

  require_cmd gh
  [[ -f "$binary_path" ]] || die "Binary file not found: $binary_path"

  if (cd "$PROJECT_ROOT" && gh release view "$tag" >/dev/null 2>&1); then
    die "GitHub release $tag already exists"
  fi

  (cd "$PROJECT_ROOT" && gh release create "$tag" "$binary_path#markspresso-linux-amd64" --title "$tag" --generate-notes --verify-tag)
  log_success "Created GitHub release $tag and uploaded $(basename "$binary_path")"
}

release_local() {
  require_cmd git
  require_cmd jq
  ensure_clean_git

  local version tag binary_path
  version="$(get_current_version)"
  [[ -n "$version" ]] || die "module.json is missing a non-empty version field"
  tag="v$version"

  ensure_tag_available "$tag"
  build_binary
  binary_path="$(resolve_binary_path)"

  create_and_push_tag "$tag"
  create_github_release "$tag" "$binary_path"
  log_success "Release complete for $tag"
}

release_via_ci() {
  require_cmd git
  require_cmd jq
  ensure_clean_git

  local version tag
  version="$(get_current_version)"
  [[ -n "$version" ]] || die "module.json is missing a non-empty version field"
  tag="v$version"

  ensure_tag_available "$tag"
  create_and_push_tag "$tag"
  log_info "Tag pushed. GitHub Actions workflow should build and publish the release artifact."
}

check_status() {
  require_cmd git
  require_cmd jq

  local current_version
  current_version="$(get_current_version)"

  echo
  log_info "markspresso Release Status"
  echo "=========================="
  echo "Current version: ${current_version:-<missing>}"
  echo "Module file: $MODULE_JSON"
  echo
  log_info "Git Status"
  echo "=========="
  git -C "$PROJECT_ROOT" status --short
  echo
  log_info "Recent commits"
  echo "=============="
  git -C "$PROJECT_ROOT" --no-pager log --oneline -5
  echo
  log_info "Recent tags"
  echo "==========="
  git -C "$PROJECT_ROOT" tag -l "v*" --sort=-version:refname | sed -n '1,5p'
}

show_help() {
  cat << EOF
markspresso Release Management Script

Usage: $0 <command> [options]

Commands:
  status                       Show current version and git status
  bump <major|minor|patch>     Bump module.json version
  set-version <X.Y.Z[-suffix]> Set an explicit module.json version
  build-binary                 Build markspresso binary locally
  release                      Build binary, create/push tag, create GitHub release, upload binary
  release-ci                   Create/push tag only (GitHub workflow performs build/release)
  help                         Show this help text

Environment variables:
  LUCLI_DIR                    Path to local LuCLI checkout (used by build script)
  BINARY_PATH                  Override binary path for release asset upload

Examples:
  $0 bump patch
  $0 set-version 2.0.0-rc1
  LUCLI_DIR=~/Code/DistroKid/LuCLI $0 build-binary
  LUCLI_DIR=~/Code/DistroKid/LuCLI $0 release
  $0 release-ci
EOF
}

main() {
  case "${1:-}" in
    status)
      check_status
      ;;
    bump)
      [[ -n "${2:-}" ]] || die "Version type required: major, minor, or patch"
      bump_version "$2"
      ;;
    set-version)
      [[ -n "${2:-}" ]] || die "Version value required"
      set_version_explicit "$2"
      ;;
    build-binary)
      require_cmd jq
      build_binary
      ;;
    release)
      release_local
      ;;
    release-ci)
      release_via_ci
      ;;
    ""|help|--help|-h)
      show_help
      ;;
    *)
      log_error "Unknown command: ${1:-}"
      echo
      show_help
      exit 1
      ;;
  esac
}

main "${@:-}"
