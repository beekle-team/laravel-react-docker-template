#!/bin/bash
# PostToolUse hook: format edited files with Pint / Biome.

set -e

INPUT="$(cat)"
HOOK_DIR="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=lib-event.sh
source "$HOOK_DIR/lib-event.sh"
PROJECT_ROOT="$(event_project_root "$INPUT")"
export AI_PROJECT_ROOT="$PROJECT_ROOT"

# shellcheck source=lib-project.sh
source "$HOOK_DIR/lib-project.sh"

FILE_PATHS=()
while IFS= read -r repo_path; do
  [ -n "$repo_path" ] && FILE_PATHS+=("$repo_path")
done < <(event_repo_paths "$INPUT" "$PROJECT_ROOT")

if [ "${#FILE_PATHS[@]}" -eq 0 ]; then
  printf 'No supported edited files in hook input; skipping.\n' >&2
  exit 0
fi

for REPO_PATH in "${FILE_PATHS[@]}"; do
  FILE_PATH="$PROJECT_ROOT/$REPO_PATH"
  [ -f "$FILE_PATH" ] || continue
  EXT="${REPO_PATH##*.}"

  case "$EXT" in
    php)
      if php_tooling_available; then
        php_exec ./vendor/bin/pint "$(container_path "$REPO_PATH")" --quiet 2>/dev/null || true
      fi
      ;;
    ts|tsx|js|jsx)
      APP_PATH="${REPO_PATH#src/}"
      if [ -x "$APP_DIR/node_modules/.bin/biome" ]; then
        (cd "$APP_DIR" && ./node_modules/.bin/biome format --write "$APP_PATH" 2>/dev/null) || true
      elif [ -x "$APP_DIR/node_modules/.bin/prettier" ]; then
        (cd "$APP_DIR" && ./node_modules/.bin/prettier --write "$APP_PATH" 2>/dev/null) || true
      fi
      ;;
  esac
done

exit 0
