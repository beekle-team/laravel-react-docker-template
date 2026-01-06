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
