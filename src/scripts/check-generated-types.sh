#!/usr/bin/env bash
set -euo pipefail

GENERATED_FILE="resources/js/types/generated.d.ts"

if [[ ! -f "$GENERATED_FILE" ]]; then
    echo "Generated TypeScript types are not tracked." >&2
    echo "Run: composer types && git add $GENERATED_FILE" >&2
    exit 1
fi

SNAPSHOT="$(mktemp)"
trap 'rm -f "$SNAPSHOT"' EXIT
cp "$GENERATED_FILE" "$SNAPSHOT"

php artisan typescript:transform

if ! cmp -s "$SNAPSHOT" "$GENERATED_FILE"; then
    echo "Generated TypeScript types are out of date." >&2
    echo "Run: composer types" >&2
    diff -u "$SNAPSHOT" "$GENERATED_FILE" >&2 || true
    exit 1
fi

echo "Generated TypeScript types are current."
