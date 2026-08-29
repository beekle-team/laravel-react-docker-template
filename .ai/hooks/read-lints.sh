#!/bin/bash
# Read lints for specified files
# Usage: read-lints.sh file1 file2 ...

set -e

# shellcheck source=lib-project.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-project.sh"
ERRORS=0

for FILE in "$@"; do
  REPO_PATH="$(repo_path "$FILE")"
  FILE_PATH="$PROJECT_ROOT/$REPO_PATH"

  if [ ! -f "$FILE_PATH" ]; then
    continue
  fi

  EXT="${REPO_PATH##*.}"

  case "$EXT" in
    php)
      echo "=== PHPStan: $REPO_PATH ==="
      if php_tooling_available; then
        php_exec ./vendor/bin/phpstan analyse "$(container_path "$REPO_PATH")" --no-progress 2>&1 || ERRORS=1
      fi
      ;;
    ts|tsx)
      echo "=== TypeScript: $REPO_PATH ==="
      (cd "$APP_DIR" && npm run types 2>&1) || ERRORS=1
      ;;
    js|jsx)
      echo "=== Biome: $REPO_PATH ==="
      if [ -x "$APP_DIR/node_modules/.bin/biome" ]; then
        (cd "$APP_DIR" && ./node_modules/.bin/biome lint "${REPO_PATH#src/}" 2>&1) || ERRORS=1
      fi
      ;;
  esac
done

exit $ERRORS
