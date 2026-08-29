#!/usr/bin/env bash
set -euo pipefail

GENERATED_FILE="resources/js/types/generated.d.ts"

php artisan typescript:transform

if ! git diff --quiet -- "$GENERATED_FILE"; then
    echo "Generated TypeScript types are out of date." >&2
    echo "Run: composer types" >&2
    git --no-pager diff -- "$GENERATED_FILE" >&2
    exit 1
fi

if [ -n "$(git ls-files --others --exclude-standard -- "$GENERATED_FILE")" ]; then
    echo "Generated TypeScript types are not tracked." >&2
    echo "Run: composer types && git add $GENERATED_FILE" >&2
    exit 1
fi

echo "Generated TypeScript types are current."
