#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"

install_line="$(grep '^RUN docker-php-ext-install ' "$PROJECT_ROOT/Dockerfile")"

if [[ " $install_line " == *" opcache "* ]]; then
    printf 'FAIL: php:8.5-fpm already provides OPcache; reinstalling it breaks clean builds.\n' >&2
    exit 1
fi

printf 'PASS: Dockerfile does not reinstall the OPcache bundled with PHP 8.5.\n'
