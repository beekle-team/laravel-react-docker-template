#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

create_project() {
    local project_dir="$1"

    mkdir -p "$project_dir/scripts" "$project_dir/src" "$project_dir/bin"
    cp "$PROJECT_ROOT/scripts/setup.sh" "$project_dir/scripts/setup.sh"
    cp "$PROJECT_ROOT/scripts/compose.sh" "$project_dir/scripts/compose.sh"
    cp "$PROJECT_ROOT/src/.env.example" "$project_dir/src/.env.example"

    cat > "$project_dir/bin/docker" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$DOCKER_CALLS"
EOF
    chmod +x "$project_dir/bin/docker"
}

FRESH_PROJECT="$TEST_ROOT/fresh"
create_project "$FRESH_PROJECT"

DOCKER_CALLS="$FRESH_PROJECT/docker.calls" \
PATH="$FRESH_PROJECT/bin:$PATH" \
    "$FRESH_PROJECT/scripts/setup.sh" > "$FRESH_PROJECT/output"

test -f "$FRESH_PROJECT/src/.env"
grep -Fx 'compose version' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env build app' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env run --rm --no-deps --user root app sh -c chown "$(stat -c "%u:%g" /var/www)" /var/www/vendor /var/www/node_modules' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env run --rm --no-deps app composer install --no-interaction --prefer-dist' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env run --rm --no-deps app npm ci' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env run --rm --no-deps app php artisan key:generate --ansi' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env up -d --wait postgres redis mailpit' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env run --rm app php artisan migrate --force --ansi' "$FRESH_PROJECT/docker.calls" >/dev/null
grep -Fx 'compose --env-file src/.env up -d app nginx vite' "$FRESH_PROJECT/docker.calls" >/dev/null

if grep -F 'APP_KEY=' "$FRESH_PROJECT/output"; then
    printf 'FAIL: setup output exposed the APP_KEY setting\n' >&2
    exit 1
fi

EXISTING_PROJECT="$TEST_ROOT/existing"
create_project "$EXISTING_PROJECT"
cp "$EXISTING_PROJECT/src/.env.example" "$EXISTING_PROJECT/src/.env"
perl -0pi -e 's/^APP_KEY=.*$/APP_KEY=base64:existing-key/m' "$EXISTING_PROJECT/src/.env"

DOCKER_CALLS="$EXISTING_PROJECT/docker.calls" \
PATH="$EXISTING_PROJECT/bin:$PATH" \
    "$EXISTING_PROJECT/scripts/setup.sh" > "$EXISTING_PROJECT/output"

grep -Fx 'APP_KEY=base64:existing-key' "$EXISTING_PROJECT/src/.env" >/dev/null
if grep -F 'key:generate' "$EXISTING_PROJECT/docker.calls"; then
    printf 'FAIL: setup replaced an existing APP_KEY\n' >&2
    exit 1
fi

printf 'PASS: setup initializes a fresh project and preserves an existing APP_KEY.\n'
