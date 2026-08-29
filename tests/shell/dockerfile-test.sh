#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

install_line="$(grep '^RUN docker-php-ext-install ' "$PROJECT_ROOT/Dockerfile")"

if [[ " $install_line " == *" opcache "* ]]; then
    printf 'FAIL: php:8.5-fpm already provides OPcache; reinstalling it breaks clean builds.\n' >&2
    exit 1
fi

if ! grep -F 'install -d -o "$user" -g "$user" /var/www/vendor /var/www/node_modules' "$PROJECT_ROOT/Dockerfile" >/dev/null; then
    printf 'FAIL: dependency volume mount points are not owned by the non-root app user.\n' >&2
    exit 1
fi

printf 'PASS: Dockerfile is compatible with PHP 8.5 and non-root dependency volumes.\n'
