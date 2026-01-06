#!/bin/bash
# Post-edit hook: lint only (tests run on commit)
# Checks PHP and TypeScript files after editing

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

EXT="${FILE_PATH##*.}"
PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"

case "$EXT" in
  php)
    # Run PHPStan on the file
    if [ -f "$PROJECT_ROOT/vendor/bin/phpstan" ]; then
      echo "📋 Analyzing: $(basename "$FILE_PATH")"
      "$PROJECT_ROOT/vendor/bin/phpstan" analyze "$FILE_PATH" --no-progress 2>&1 || true
    fi
    ;;
  ts|tsx)
    # Run TypeScript check
    if [ -f "$PROJECT_ROOT/node_modules/.bin/tsc" ]; then
      echo "📋 Type checking: $(basename "$FILE_PATH")"
      # Use tsc with --noEmit to just check types
      cd "$PROJECT_ROOT" && npm run types 2>&1 | head -20 || true
    fi
    ;;
  js|jsx)
    # Run Biome lint
    if [ -f "$PROJECT_ROOT/node_modules/.bin/biome" ]; then
      echo "📋 Linting: $(basename "$FILE_PATH")"
      "$PROJECT_ROOT/node_modules/.bin/biome" lint "$FILE_PATH" 2>&1 || true
    fi
    ;;
esac

exit 0
