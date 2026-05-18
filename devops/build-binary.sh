#!/usr/bin/env bash
set -euo pipefail

die() {
  echo "ERROR: $*" >&2
  exit 1
}

require_cmd() {
  local cmd="$1"
  command -v "$cmd" >/dev/null 2>&1 || die "Required command not found: $cmd"
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MARKSPRESSO_DIR="${MARKSPRESSO_DIR:-$(cd "$SCRIPT_DIR/.." && pwd)}"

if [[ -n "${GITHUB_WORKSPACE:-}" ]]; then
  DEFAULT_LUCLI_DIR="$GITHUB_WORKSPACE/LuCLI"
else
  DEFAULT_LUCLI_DIR="$(cd "$MARKSPRESSO_DIR/.." && pwd)/LuCLI"
fi
LUCLI_DIR="${LUCLI_DIR:-$DEFAULT_LUCLI_DIR}"

LUCLI_REPO="${LUCLI_REPO:-https://github.com/cybersonic/LuCLI.git}"
LUCLI_REF="${LUCLI_REF:-feature/white-label-branding}"
AUTO_CLONE_LUCLI="${AUTO_CLONE_LUCLI:-0}"
ENSURE_LUCLI_REF="${ENSURE_LUCLI_REF:-0}"

require_cmd jq
require_cmd rsync
require_cmd mvn

[[ -d "$MARKSPRESSO_DIR" ]] || die "MARKSPRESSO_DIR does not exist: $MARKSPRESSO_DIR"
[[ -f "$MARKSPRESSO_DIR/module.json" ]] || die "module.json not found in: $MARKSPRESSO_DIR"

if [[ ! -d "$LUCLI_DIR" ]]; then
  if [[ "$AUTO_CLONE_LUCLI" != "1" ]]; then
    die "LUCLI_DIR does not exist: $LUCLI_DIR (set LUCLI_DIR or AUTO_CLONE_LUCLI=1)"
  fi
  require_cmd git
  mkdir -p "$(dirname "$LUCLI_DIR")"
  git clone --depth 1 --branch "$LUCLI_REF" "$LUCLI_REPO" "$LUCLI_DIR"
fi

if [[ "$ENSURE_LUCLI_REF" == "1" && -d "$LUCLI_DIR/.git" ]]; then
  require_cmd git
  git -C "$LUCLI_DIR" fetch --depth 1 origin "$LUCLI_REF"
  git -C "$LUCLI_DIR" checkout "$LUCLI_REF"
fi

MARKSPRESSO_VERSION="$(jq -r '.version // empty' "$MARKSPRESSO_DIR/module.json")"
MARKSPRESSO_VERSION="${MARKSPRESSO_VERSION//$'\r'/}"
BANNER_FILE="${BANNER_FILE:-$MARKSPRESSO_DIR/assets/markspresso-logo-ascii.txt}"

if [[ -z "$MARKSPRESSO_VERSION" ]]; then
  die "module.json is missing a non-empty 'version' field"
fi
[[ -f "$BANNER_FILE" ]] || die "Banner ASCII file not found: $BANNER_FILE"

BANNER_ASCII="$(<"$BANNER_FILE")"
BANNER_ASCII="${BANNER_ASCII//$'\r'/}"
BANNER_ASCII_ESCAPED="${BANNER_ASCII//$'\n'/\\n}"
BANNER_TEXT="${BANNER_ASCII_ESCAPED}\\nMarkspresso\\nPowered by LuCLI Version: \${LUCLI_VERSION}"

echo "Resolved Markspresso version: $MARKSPRESSO_VERSION"

if [[ -n "${GITHUB_ENV:-}" ]]; then
  echo "MARKSPRESSO_VERSION=$MARKSPRESSO_VERSION" >> "$GITHUB_ENV"
fi

MODULE_INSTALL_DIR="$LUCLI_DIR/target/modules-install/markspresso"

pushd "$LUCLI_DIR" >/dev/null
mvn clean -Dmaven.test.skip=true

# Populate bundled module content after clean, before package resources are processed.
mkdir -p "$MODULE_INSTALL_DIR"
rsync -a --delete \
  --exclude ".git" \
  "$MARKSPRESSO_DIR/" \
  "$MODULE_INSTALL_DIR/"

mvn package \
  -Dmaven.test.skip=true \
  -Djreleaser.dry.run=true \
  -Dbranding.enabled=true \
  -Dbranding.binaryName=markspresso \
  -Dbranding.profileName=markspresso \
  -Dbranding.displayName=Markspresso \
  -Dbranding.promptPrefix=markspresso \
  -Dbranding.homeDirName=.markspresso \
  -Dbranding.backupsDirName=.markspresso_backups \
  -Dbranding.productVersion="${MARKSPRESSO_VERSION}" \
  -Dbranding.bannerText="${BANNER_TEXT}"

cat src/bin/lucli.sh target/lucli.jar > target/markspresso
chmod 755 target/markspresso

./target/markspresso --version
./target/markspresso --help
popd >/dev/null

BINARY_PATH="$LUCLI_DIR/target/markspresso"
echo "Built binary: $BINARY_PATH"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  echo "markspresso_version=$MARKSPRESSO_VERSION" >> "$GITHUB_OUTPUT"
  echo "binary_path=$BINARY_PATH" >> "$GITHUB_OUTPUT"
fi
