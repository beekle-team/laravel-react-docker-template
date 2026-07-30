#!/bin/bash
# Pre-commit hook: Run lint and tests before allowing commit
# Blocks commit if lint errors or test failures exist

set -e

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
ERRORS=0

echo "=== Pre-commit Check ==="

# Get staged files
STAGED_PHP=$(git diff --cached --name-only --diff-filter=ACMR | grep '\.php$' || true)
STAGED_TS=$(git diff --cached --name-only --diff-filter=ACMR | grep -E '\.(ts|tsx|js|jsx)$' || true)

# PHP checks (Laravel)
if [ -n "$STAGED_PHP" ]; then
  echo ">>> PHP: Running Pint..."
  cd "$PROJECT_DIR"

  SERVICE_LAYER_FILES=""
  while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue

    if [[ "$FILE" == src/app/Services/* || "$FILE" == src/app/Actions/* ]]; then
      SERVICE_LAYER_FILES="${SERVICE_LAYER_FILES}${FILE}
"
      continue
    fi

    if [[ "$FILE" == src/app/*Service.php || "$FILE" == src/app/**/*Service.php ]]; then
      if [[ "$FILE" != src/app/Providers/*ServiceProvider.php ]]; then
        SERVICE_LAYER_FILES="${SERVICE_LAYER_FILES}${FILE}
"
      fi
    fi
  done < <(printf '%s\n' "$STAGED_PHP")
  if [ -n "$SERVICE_LAYER_FILES" ]; then
    echo "BLOCK: Service / Action classes are not allowed."
    echo "$SERVICE_LAYER_FILES"
    echo "Place DB logic in Eloquent Models, external API logic in Models/Gateway, and shared model behavior in Models/Concerns."
    ERRORS=1
  fi

  CONTROLLER_VALIDATION=""
  while IFS= read -r FILE; do
    [ -z "$FILE" ] && continue
    MATCHES=$(grep -nE '(\$request->validate\(|request\(\)->validate\()' "$FILE" 2>/dev/null || true)
    if [ -n "$MATCHES" ]; then
      CONTROLLER_VALIDATION="${CONTROLLER_VALIDATION}${FILE}:${MATCHES}
"
    fi
  done < <(printf '%s\n' "$STAGED_PHP" | grep '^src/app/Http/Controllers/.*\.php$' || true)
  if [ -n "$CONTROLLER_VALIDATION" ]; then
    echo "BLOCK: Controller input validation must use Form Request objects."
    echo "$CONTROLLER_VALIDATION"
    echo "Move rules to app/Http/Requests/** and read validated data with \$request->validated()."
    ERRORS=1
  fi

  if ! ./vendor/bin/pint --test 2>&1; then
    echo "BLOCK: Pint found formatting issues. Run: composer pint"
    ERRORS=1
  fi

  echo ">>> PHP: Running PHPStan..."
  if ! ./vendor/bin/phpstan analyze --no-progress 2>&1; then
    echo "BLOCK: PHPStan found issues"
    ERRORS=1
  fi

  echo ">>> PHP: Running Pest tests..."
  if ! php artisan test --stop-on-failure 2>&1; then
    echo "BLOCK: Pest tests failed"
    ERRORS=1
  fi
fi

# TypeScript/JavaScript checks (React)
if [ -n "$STAGED_TS" ]; then
  echo ">>> TypeScript: Running Biome lint..."
  ORIGINAL_DIR=$(pwd)
  cd "$PROJECT_DIR/src"

  if ! npm run lint:js 2>&1; then
    echo "BLOCK: Biome lint failed"
    ERRORS=1
  fi

  echo ">>> TypeScript: Type checking..."
  if ! npm run types 2>&1; then
    echo "BLOCK: TypeScript type check failed"
    ERRORS=1
  fi

  echo ">>> TypeScript: Running Vitest..."
  if ! npm run test -- --run 2>&1; then
    echo "BLOCK: Vitest tests failed"
    ERRORS=1
  fi

  cd "$ORIGINAL_DIR"
fi

if [ $ERRORS -ne 0 ]; then
  echo ""
  echo "BLOCKED: Fix the above issues before committing."
  echo "Use '/verify --quick' for quick lint-only validation."
  exit 1
fi

echo "=== Pre-commit Check Passed ==="
exit 0
