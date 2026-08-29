#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
ENV_FILE="$PROJECT_ROOT/src/.env"

if [[ ! -f "$ENV_FILE" ]]; then
    printf 'src/.env がありません。先に scripts/setup.sh を実行してください。\n' >&2
    exit 1
fi

cd "$PROJECT_ROOT"
exec docker compose --env-file src/.env "$@"
