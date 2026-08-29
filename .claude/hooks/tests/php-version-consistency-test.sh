#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p \
  "$TMP_ROOT/.github/workflows" \
  "$TMP_ROOT/scripts" \
  "$TMP_ROOT/src"

cp "$PROJECT_ROOT/scripts/check-php-version-consistency.sh" "$TMP_ROOT/scripts/"
printf '8.5\n' > "$TMP_ROOT/.php-version"
printf 'FROM php:8.5-fpm\n' > "$TMP_ROOT/Dockerfile"
printf '{"require":{"php":"^8.5"}}\n' > "$TMP_ROOT/src/composer.json"
cat > "$TMP_ROOT/src/rector.php" <<'PHP'
<?php

return RectorConfig::configure()
    ->withPhpSets(php85: true)
    ->withPhpVersion(PhpVersion::PHP_85);
PHP
cat > "$TMP_ROOT/.github/workflows/ci.yml" <<'YAML'
steps:
  - uses: shivammathur/setup-php@v2
    with:
      php-version: 8.5
YAML

git -C "$TMP_ROOT" init -q
git -C "$TMP_ROOT" config user.email guard-test@example.com
git -C "$TMP_ROOT" config user.name 'Guard Test'
git -C "$TMP_ROOT" add .
git -C "$TMP_ROOT" commit -qm initial

(
  cd "$TMP_ROOT"
  bash scripts/check-php-version-consistency.sh >/dev/null
)

sed -i 's/php-version: 8.5/php-version: 8.6/' "$TMP_ROOT/.github/workflows/ci.yml"

set +e
OUTPUT="$(cd "$TMP_ROOT" && bash scripts/check-php-version-consistency.sh 2>&1)"
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  printf 'FAIL: PHP 8.6 was accepted even though the repository standard is 8.5.\n%s\n' "$OUTPUT" >&2
  exit 1
fi

if ! grep -Fq 'other than 8.5' <<< "$OUTPUT"; then
  printf 'FAIL: guard failed without the expected version mismatch message.\n%s\n' "$OUTPUT" >&2
  exit 1
fi

printf 'PASS: workflow PHP versions other than 8.5 are rejected.\n'
