#!/bin/bash
# PostToolUse hook: format edited files with Pint / Biome.

set -e

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# shellcheck source=lib-project.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-project.sh"

EXT="${FILE_PATH##*.}"

case "$EXT" in
  php)
    if php_tooling_available; then
      php_exec ./vendor/bin/pint "$(container_path "$FILE_PATH")" --quiet 2>/dev/null || true
    fi
    ;;
  ts|tsx|js|jsx)
    if [ -x "$APP_DIR/node_modules/.bin/biome" ]; then
      (cd "$APP_DIR" && ./node_modules/.bin/biome format --write "$FILE_PATH" 2>/dev/null) || true
    elif [ -x "$APP_DIR/node_modules/.bin/prettier" ]; then
      (cd "$APP_DIR" && ./node_modules/.bin/prettier --write "$FILE_PATH" 2>/dev/null) || true
    fi
    ;;
esac

exit 0
