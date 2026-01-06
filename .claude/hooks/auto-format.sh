#!/bin/bash
# Auto-format hook for PostToolUse (Edit/Write)
# Formats PHP and TypeScript/JavaScript files automatically

set -e

# Read tool input from stdin
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit if no file path
if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Get project root (where composer.json is)
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Format based on file type
case "$EXT" in
  php)
    # Format PHP with Laravel Pint
    if [ -f "$PROJECT_ROOT/vendor/bin/pint" ]; then
      "$PROJECT_ROOT/vendor/bin/pint" "$FILE_PATH" --quiet 2>/dev/null || true
    fi
    ;;
  ts|tsx|js|jsx)
    # Format TypeScript/JavaScript with Biome
    if [ -f "$PROJECT_ROOT/node_modules/.bin/biome" ]; then
      "$PROJECT_ROOT/node_modules/.bin/biome" format --write "$FILE_PATH" 2>/dev/null || true
    # Fallback to Prettier
    elif [ -f "$PROJECT_ROOT/node_modules/.bin/prettier" ]; then
      "$PROJECT_ROOT/node_modules/.bin/prettier" --write "$FILE_PATH" 2>/dev/null || true
    fi
    ;;
esac

exit 0
