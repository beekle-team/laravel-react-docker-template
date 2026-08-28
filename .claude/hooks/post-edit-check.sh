#!/bin/bash
# PostToolUse hook: architecture guards + per-file lint.
#
# Architecture violations exit 2 so the message is fed back to Claude.
# Lint output is informational and never blocks (tests run on commit).

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

[ -z "$FILE_PATH" ] && exit 0

# shellcheck source=lib-project.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-project.sh"

REPO_PATH="$(repo_path "$FILE_PATH")"
EXT="${FILE_PATH##*.}"
VIOLATIONS=""

add_violation() {
  VIOLATIONS="${VIOLATIONS}$1
"
}

case "$EXT" in
  php)
    # Service / Action classes become generic buckets; keep logic in Models.
    if [[ "$REPO_PATH" == src/app/Services/* || "$REPO_PATH" == src/app/Actions/* ]]; then
      add_violation "BLOCK: Service / Action classes are not allowed ($REPO_PATH).
Place DB logic in Eloquent Models, external API logic in App\\Models\\Gateway, and shared model behavior in App\\Models\\Concerns."
    elif [[ "$REPO_PATH" == src/app/*Service.php && "$REPO_PATH" != src/app/Providers/*ServiceProvider.php ]]; then
      add_violation "BLOCK: Service classes are not allowed ($REPO_PATH).
Place DB logic in Eloquent Models, external API logic in App\\Models\\Gateway, and shared model behavior in App\\Models\\Concerns."
    fi

    # Enforce Form Request based input validation in controllers.
    if [[ "$REPO_PATH" == src/app/Http/Controllers/* ]]; then
      MATCHES=$(grep -nE '(\$request->validate\(|request\(\)->validate\()' "$FILE_PATH" || true)
      if [ -n "$MATCHES" ]; then
        add_violation "BLOCK: Controller input validation must use a Form Request object ($REPO_PATH).
$MATCHES
Move rules to app/Http/Requests/** and read validated data with \$request->validated()."
      fi
    fi
    ;;
  ts|tsx|js|jsx)
    MATCHES=$(grep -nE '(:| as |<|,|\(|\[|\{|=)\s*any\b|Array<\s*any\s*>|Record<[^>]*,\s*any\s*>' "$FILE_PATH" || true)
    if [ -n "$MATCHES" ]; then
      add_violation "BLOCK: TypeScript any is not allowed ($REPO_PATH).
$MATCHES
Use generated Data types, precise local Props, unknown, or a generic type parameter instead."
    fi

    if [[ "$REPO_PATH" == src/resources/js/types/* \
       && "$REPO_PATH" != src/resources/js/types/generated.d.ts \
       && "$REPO_PATH" != src/resources/js/types/vite-env.d.ts ]]; then
      MATCHES=$(grep -nE '^\s*export\s+(interface|type)\s+' "$FILE_PATH" || true)
      if [ -n "$MATCHES" ]; then
        add_violation "BLOCK: Manual exported types under resources/js/types are not allowed ($REPO_PATH).
$MATCHES
Create app/Data/** with #[TypeScript], run php artisan typescript:transform, and use resources/js/types/generated.d.ts."
      fi
    fi
    ;;
esac

if [ -n "$VIOLATIONS" ]; then
  printf '%s' "$VIOLATIONS" >&2
  exit 2
fi

# Informational lint. Never blocks; full type check and tests run on commit.
case "$EXT" in
  php)
    if php_tooling_available; then
      echo "Analyzing: $(basename "$FILE_PATH")"
      php_exec ./vendor/bin/phpstan analyse "$(container_path "$FILE_PATH")" --no-progress 2>&1 || true
    fi
    ;;
  ts|tsx|js|jsx)
    if [ -x "$APP_DIR/node_modules/.bin/biome" ]; then
      echo "Linting: $(basename "$FILE_PATH")"
      (cd "$APP_DIR" && ./node_modules/.bin/biome lint "$FILE_PATH" 2>&1) || true
    fi
    ;;
esac

exit 0
