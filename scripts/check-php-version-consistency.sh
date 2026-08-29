#!/usr/bin/env bash
set -euo pipefail

EXPECTED_VERSION="8.5"
ERRORS=0

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  ERRORS=1
}

if [ "$(tr -d '[:space:]' < .php-version)" != "$EXPECTED_VERSION" ]; then
  fail ".php-version must be $EXPECTED_VERSION"
fi

if ! grep -Eq '"php"[[:space:]]*:[[:space:]]*"\^8\.5"' src/composer.json; then
  fail "src/composer.json must require PHP ^8.5"
fi

if ! grep -Fq 'FROM php:8.5-fpm' Dockerfile; then
  fail "Dockerfile must use php:8.5-fpm"
fi

DOCKER_PHP_EXTENSIONS="$(awk '
  function print_extensions(instruction, segments, segment_count, segment_index, argument_count, arguments, argument_index, argument) {
    if (instruction !~ /^[[:space:]]*[Rr][Uu][Nn][[:space:]]+/) {
      return
    }

    sub(/^[[:space:]]*[Rr][Uu][Nn][[:space:]]+/, "", instruction)
    segment_count = split(instruction, segments, /&&|[|]+|;/)

    for (segment_index = 1; segment_index <= segment_count; segment_index++) {
      if (segments[segment_index] !~ /^[[:space:]]*docker-php-ext-install[[:space:]]+/) {
        continue
      }

      sub(/^[[:space:]]*docker-php-ext-install[[:space:]]+/, "", segments[segment_index])
      argument_count = split(segments[segment_index], arguments, /[[:space:]]+/)

      for (argument_index = 1; argument_index <= argument_count; argument_index++) {
        argument = arguments[argument_index]

        if (argument == "" || argument ~ /^#/) {
          break
        }

        gsub(/^["\047]+/, "", argument)
        gsub(/["\047]+$/, "", argument)
        print argument
      }
    }
  }

  /^[[:space:]]*#/ {
    next
  }

  {
    line = $0
    continuing = (line ~ /\\[[:space:]]*$/)
    sub(/[[:space:]]*\\[[:space:]]*$/, " ", line)
    instruction = instruction line " "

    if (!continuing) {
      print_extensions(instruction)
      instruction = ""
    }
  }
' Dockerfile)"

for bundled_extension in pdo mbstring opcache; do
  if grep -Eq "(^|[[:space:]])${bundled_extension}([[:space:]]|$)" <<< "$DOCKER_PHP_EXTENSIONS"; then
    fail "Dockerfile must not reinstall extensions bundled with php:8.5-fpm: $bundled_extension"
  fi
done

if ! grep -Fq 'withPhpSets(php85: true)' src/rector.php \
  || ! grep -Fq 'PhpVersion::PHP_85' src/rector.php; then
  fail "src/rector.php must target PHP 8.5"
fi

INVALID_WORKFLOW_VERSIONS=""
while IFS= read -r line; do
  [ -z "$line" ] && continue

  value="${line#*php-version:}"
  value="${value%%#*}"
  value="$(printf '%s' "$value" | tr -d "[:space:]'\"")"

  if [ "$value" != "$EXPECTED_VERSION" ]; then
    INVALID_WORKFLOW_VERSIONS="${INVALID_WORKFLOW_VERSIONS}${line}\n"
  fi
done < <(grep -RInE '^[[:space:]]*php-version:[[:space:]]*' .github/workflows || true)

if [ -n "$INVALID_WORKFLOW_VERSIONS" ]; then
  fail "GitHub Actions contains a PHP version other than 8.5:\n${INVALID_WORKFLOW_VERSIONS%\\n}"
fi

# The guard necessarily contains the legacy tokens in its search expression,
# so exclude itself from the repository scan.
OLD_RECTOR_TARGETS=$(git grep -nE 'PHP 8\.3|php83|PHP_83' -- \
  ':!src/composer.lock' \
  ':!scripts/check-php-version-consistency.sh' || true)
if [ -n "$OLD_RECTOR_TARGETS" ]; then
  fail "Old PHP 8.3 project targets remain:\n$OLD_RECTOR_TARGETS"
fi

if [ "$ERRORS" -ne 0 ]; then
  exit 1
fi

printf 'PASS: PHP is consistently pinned to %s.\n' "$EXPECTED_VERSION"
