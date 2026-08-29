#!/bin/bash
# PostToolUse hook: architecture guards + per-file lint.
#
# Architecture violations exit 2 so the message is fed back to the invoking agent.
# Lint output is informational and never blocks (tests run on commit).

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

VIOLATIONS=""

add_violation() {
  VIOLATIONS="${VIOLATIONS}$1
"
}

for REPO_PATH in "${FILE_PATHS[@]}"; do
  FILE_PATH="$PROJECT_ROOT/$REPO_PATH"
  [ -f "$FILE_PATH" ] || continue
  EXT="${REPO_PATH##*.}"

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
done

if [ -n "$VIOLATIONS" ]; then
  printf '%s' "$VIOLATIONS" >&2
  exit 2
fi

# Informational lint. Never blocks; full type check and tests run on commit.
for REPO_PATH in "${FILE_PATHS[@]}"; do
  FILE_PATH="$PROJECT_ROOT/$REPO_PATH"
  [ -f "$FILE_PATH" ] || continue
  EXT="${REPO_PATH##*.}"

  case "$EXT" in
    php)
      if php_tooling_available; then
        echo "Analyzing: $(basename "$FILE_PATH")"
        php_exec ./vendor/bin/phpstan analyse "$(container_path "$REPO_PATH")" --no-progress 2>&1 || true
      fi
      ;;
    ts|tsx|js|jsx)
      APP_PATH="${REPO_PATH#src/}"
      if [ -x "$APP_DIR/node_modules/.bin/biome" ]; then
        echo "Linting: $(basename "$FILE_PATH")"
        (cd "$APP_DIR" && ./node_modules/.bin/biome lint "$APP_PATH" 2>&1) || true
      fi
      ;;
  esac
done

exit 0
