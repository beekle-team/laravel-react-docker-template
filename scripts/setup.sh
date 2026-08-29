#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ENV_FILE="$PROJECT_ROOT/src/.env"
ENV_EXAMPLE="$PROJECT_ROOT/src/.env.example"
COMPOSE="$PROJECT_ROOT/scripts/compose.sh"

if ! command -v docker >/dev/null 2>&1; then
    printf 'Docker が見つかりません。Docker をインストールして再実行してください。\n' >&2
    exit 1
fi

docker compose version >/dev/null

if [[ ! -f "$ENV_FILE" ]]; then
    cp "$ENV_EXAMPLE" "$ENV_FILE"
fi

"$COMPOSE" build app
"$COMPOSE" run --rm --no-deps --user root app sh -c \
    'chown "$(stat -c "%u:%g" /var/www)" /var/www/vendor /var/www/node_modules'
"$COMPOSE" run --rm --no-deps app composer install --no-interaction --prefer-dist
"$COMPOSE" run --rm --no-deps app npm ci

if ! grep -Eq '^APP_KEY=.+$' "$ENV_FILE"; then
    "$COMPOSE" run --rm --no-deps app php artisan key:generate --ansi
fi

"$COMPOSE" up -d --wait postgres redis mailpit
"$COMPOSE" run --rm app php artisan migrate --force --ansi
"$COMPOSE" up -d app nginx vite

printf '\nセットアップが完了しました。\n'
printf 'アプリ（既定）: http://localhost:8080\n'
printf 'Mailpit（既定）: http://localhost:8025\n'
