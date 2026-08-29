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
printf 'FROM php:8.5-fpm\nRUN docker-php-ext-install pdo_pgsql pgsql exif pcntl bcmath gd sockets zip\n' > "$TMP_ROOT/Dockerfile"
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

cat > "$TMP_ROOT/Dockerfile" <<'DOCKER'
FROM php:8.5-fpm
# RUN docker-php-ext-install pdo mbstring opcache
RUN docker-php-ext-install pdo_pgsql pgsql exif pcntl bcmath gd sockets zip && printf '%s\n' pdo mbstring opcache
DOCKER

set +e
OUTPUT="$(cd "$TMP_ROOT" && bash scripts/check-php-version-consistency.sh 2>&1)"
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
  printf 'FAIL: comments or chained command arguments were treated as extension arguments.\n%s\n' \
    "$OUTPUT" >&2
  exit 1
fi

for docker_argument in pdo "'pdo'" '"pdo"' mbstring "'mbstring'" '"mbstring"' opcache "'opcache'" '"opcache"'; do
  bundled_extension="$(printf '%s' "$docker_argument" | tr -d "\"'")"
  printf 'FROM php:8.5-fpm\nRUN docker-php-ext-install pdo_pgsql pgsql exif pcntl bcmath gd sockets zip %s\n' \
    "$docker_argument" > "$TMP_ROOT/Dockerfile"

  set +e
  OUTPUT="$(cd "$TMP_ROOT" && bash scripts/check-php-version-consistency.sh 2>&1)"
  STATUS=$?
  set -e

  if [ "$STATUS" -eq 0 ]; then
    printf 'FAIL: bundled extension %s was accepted for reinstallation.\n%s\n' \
      "$bundled_extension" "$OUTPUT" >&2
    exit 1
  fi

  if ! grep -Fq "bundled with php:8.5-fpm: $bundled_extension" <<< "$OUTPUT"; then
    printf 'FAIL: bundled extension %s was rejected without the expected message.\n%s\n' \
      "$bundled_extension" "$OUTPUT" >&2
    exit 1
  fi
done

printf 'PASS: php:8.5-fpm bundled extensions are rejected for reinstallation.\n'

printf 'FROM php:8.5-fpm\nRUN docker-php-ext-install pdo_pgsql pgsql exif pcntl bcmath gd sockets zip\n' > "$TMP_ROOT/Dockerfile"

sed -i.bak 's/php-version: 8.5/php-version: 8.6/' "$TMP_ROOT/.github/workflows/ci.yml"
rm "$TMP_ROOT/.github/workflows/ci.yml.bak"

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
