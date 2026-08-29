#!/bin/bash
# PreToolUse hook for `git commit`: architecture guards, lint and tests.
# Exits 2 on failure so Claude Code actually blocks the commit.

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# shellcheck source=lib-project.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib-project.sh"

ERRORS=0
REPORT=""

fail() {
  REPORT="${REPORT}$1
"
  ERRORS=1
}

echo "=== Pre-commit Check ==="

STAGED_PHP=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACMR | grep '\.php$' || true)
STAGED_COMPOSER=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACMR | grep -E '^src/composer\.(json|lock)$' || true)
# typescript-transformer.php は app_path() 全体を探索するため、app 配下の
# PHP変更は配置先にかかわらず生成型の再検証対象にする。
STAGED_TYPES_SOURCE=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACMRD | grep -E '^src/(app/.*\.php|config/typescript-transformer\.php|resources/js/types/generated\.d\.ts)$' || true)
STAGED_TS=$(git -C "$PROJECT_DIR" diff --cached --name-only --diff-filter=ACMR | grep -E '\.(ts|tsx|js|jsx)$' || true)

# composer更新や生成型だけの変更でも、PHP/Laravelバージョンと
# PHPから生成されるTypeScript型の契約を検証する。
if [ -n "$STAGED_PHP" ] || [ -n "$STAGED_COMPOSER" ] || [ -n "$STAGED_TYPES_SOURCE" ]; then
  SERVICE_LAYER_FILES=""
  CONTROLLER_VALIDATION=""

  while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue

    if [[ "$FILE" == src/app/Services/* || "$FILE" == src/app/Actions/* ]]; then
      SERVICE_LAYER_FILES="${SERVICE_LAYER_FILES}${FILE}
"
    elif [[ "$FILE" == src/app/*Service.php && "$FILE" != src/app/Providers/*ServiceProvider.php ]]; then
      SERVICE_LAYER_FILES="${SERVICE_LAYER_FILES}${FILE}
"
    fi

    if [[ "$FILE" == src/app/Http/Controllers/*.php ]]; then
      MATCHES=$(grep -nE '(\$request->validate\(|request\(\)->validate\()' "$PROJECT_DIR/$FILE" 2>/dev/null || true)
      if [ -n "$MATCHES" ]; then
        CONTROLLER_VALIDATION="${CONTROLLER_VALIDATION}${FILE}:${MATCHES}
"
      fi
    fi
  done < <(printf '%s\n' "$STAGED_PHP")

  if [ -n "$SERVICE_LAYER_FILES" ]; then
    fail "BLOCK: Service / Action classes are not allowed.
${SERVICE_LAYER_FILES}Place DB logic in Eloquent Models, external API logic in App\\Models\\Gateway, and shared model behavior in App\\Models\\Concerns."
  fi

  if [ -n "$CONTROLLER_VALIDATION" ]; then
    fail "BLOCK: Controller input validation must use Form Request objects.
${CONTROLLER_VALIDATION}Move rules to app/Http/Requests/** and read validated data with \$request->validated()."
  fi

  if ! php_tooling_available; then
    fail "BLOCK: the app container is not running, so PHP checks cannot run.
Start it with: docker compose up -d"
  else
    echo ">>> PHP: Running Pint..."
    php_exec ./vendor/bin/pint --test 2>&1 || fail "BLOCK: Pint found formatting issues. Run: docker compose exec app ./vendor/bin/pint"

    if [ -n "$STAGED_TYPES_SOURCE" ]; then
      echo ">>> PHP: Regenerating TypeScript Data types..."
      php_exec php artisan typescript:transform 2>&1 || fail "BLOCK: TypeScript type generation failed."

      if ! git -C "$PROJECT_DIR" diff --quiet -- src/resources/js/types/generated.d.ts; then
        fail "BLOCK: generated TypeScript types are out of date.
Run: docker compose exec app composer types
Then stage: src/resources/js/types/generated.d.ts"
      fi

      if [ -n "$(git -C "$PROJECT_DIR" ls-files --others --exclude-standard -- src/resources/js/types/generated.d.ts)" ]; then
        fail "BLOCK: generated TypeScript types are not tracked.
Stage: src/resources/js/types/generated.d.ts"
      fi
    fi

    echo ">>> PHP: Running Rector (version-aware dry-run)..."
    php_exec ./vendor/bin/rector process --dry-run 2>&1 || fail "BLOCK: Rector found code that must be migrated for the installed PHP/Laravel versions.
Run: docker compose exec app composer rector:fix
Then: docker compose exec app composer pint"

    echo ">>> PHP: Running PHPStan..."
    php_exec ./vendor/bin/phpstan analyse --no-progress --memory-limit=2G 2>&1 || fail "BLOCK: PHPStan found issues."

    echo ">>> PHP: Running Pest..."
    php_exec php artisan test --stop-on-failure 2>&1 || fail "BLOCK: Pest tests failed."
  fi
fi

if [ -n "$STAGED_TS" ]; then
  TYPE_SAFETY_ERRORS=""

  while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue

    ADDED_LINES=$(git -C "$PROJECT_DIR" diff --cached -U0 -- "$FILE" | grep '^+' | grep -v '^+++' || true)
    [ -z "$ADDED_LINES" ] && continue

    ANY_MATCHES=$(printf '%s\n' "$ADDED_LINES" | grep -nE '(:| as |<|,|\(|\[|\{|=)\s*any\b|Array<\s*any\s*>|Record<[^>]*,\s*any\s*>' || true)
    if [ -n "$ANY_MATCHES" ]; then
      TYPE_SAFETY_ERRORS="${TYPE_SAFETY_ERRORS}${FILE}: TypeScript any is not allowed.
${ANY_MATCHES}
"
    fi

    if [[ "$FILE" == src/resources/js/types/* \
       && "$FILE" != src/resources/js/types/generated.d.ts \
       && "$FILE" != src/resources/js/types/vite-env.d.ts ]]; then
      MANUAL_TYPES=$(printf '%s\n' "$ADDED_LINES" | grep -nE '^\+\s*export\s+(interface|type)\s+' || true)
      if [ -n "$MANUAL_TYPES" ]; then
        TYPE_SAFETY_ERRORS="${TYPE_SAFETY_ERRORS}${FILE}: Manual exported types under resources/js/types are not allowed.
${MANUAL_TYPES}
"
      fi
    fi
  done < <(printf '%s\n' "$STAGED_TS")

  if [ -n "$TYPE_SAFETY_ERRORS" ]; then
    fail "BLOCK: TypeScript types must come from Laravel Data generated types.
${TYPE_SAFETY_ERRORS}Create app/Data/** with #[TypeScript], run php artisan typescript:transform, and avoid any."
  fi

  echo ">>> TypeScript: Running Biome lint..."
  (cd "$APP_DIR" && npm run lint:js 2>&1) || fail "BLOCK: Biome lint failed."

  echo ">>> TypeScript: Type checking..."
  (cd "$APP_DIR" && npm run types 2>&1) || fail "BLOCK: TypeScript type check failed."

  echo ">>> TypeScript: Running Vitest..."
  (cd "$APP_DIR" && npm run test:unit 2>&1) || fail "BLOCK: Vitest tests failed."
fi

if [ $ERRORS -ne 0 ]; then
  {
    printf '%s' "$REPORT"
    echo "BLOCKED: Fix the above issues before committing."
  } >&2
  exit 2
fi

echo "=== Pre-commit Check Passed ==="
exit 0
