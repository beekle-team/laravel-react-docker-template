#!/bin/bash
# Read lints for specified files
# Usage: read-lints.sh file1 file2 ...

set -e

PROJECT_ROOT="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ERRORS=0

for FILE in "$@"; do
  if [ ! -f "$FILE" ]; then
    continue
  fi

  EXT="${FILE##*.}"

  case "$EXT" in
    php)
      echo "=== PHPStan: $FILE ==="
      if [ -f "$PROJECT_ROOT/vendor/bin/phpstan" ]; then
        "$PROJECT_ROOT/vendor/bin/phpstan" analyze "$FILE" --no-progress 2>&1 || ERRORS=1
      fi
      ;;
    ts|tsx)
      echo "=== TypeScript: $FILE ==="
      cd "$PROJECT_ROOT"
      npm run types 2>&1 | head -30 || ERRORS=1
      ;;
    js|jsx)
      echo "=== Biome: $FILE ==="
      if [ -f "$PROJECT_ROOT/node_modules/.bin/biome" ]; then
        "$PROJECT_ROOT/node_modules/.bin/biome" lint "$FILE" 2>&1 || ERRORS=1
      fi
      ;;
  esac
done

exit $ERRORS
