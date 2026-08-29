#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/project/scripts" "$TEST_ROOT/project/src" "$TEST_ROOT/bin"
cp "$PROJECT_ROOT/scripts/compose.sh" "$TEST_ROOT/project/scripts/compose.sh"
printf 'APP_NAME=Laravel\n' > "$TEST_ROOT/project/src/.env"

cat > "$TEST_ROOT/bin/docker" <<'EOF'
#!/usr/bin/env bash
printf 'cwd=%s\nargs=%s\n' "$PWD" "$*" >> "$DOCKER_CALLS"
EOF
chmod +x "$TEST_ROOT/bin/docker"

DOCKER_CALLS="$TEST_ROOT/docker.calls" \
PATH="$TEST_ROOT/bin:$PATH" \
    "$TEST_ROOT/project/scripts/compose.sh" ps

EXPECTED_PROJECT_ROOT="$(cd "$TEST_ROOT/project" && pwd -P)"
grep -Fx "cwd=$EXPECTED_PROJECT_ROOT" "$TEST_ROOT/docker.calls" >/dev/null
grep -Fx 'args=compose --env-file src/.env ps' "$TEST_ROOT/docker.calls" >/dev/null

rm "$TEST_ROOT/project/src/.env"

if DOCKER_CALLS="$TEST_ROOT/docker.calls" \
    PATH="$TEST_ROOT/bin:$PATH" \
    "$TEST_ROOT/project/scripts/compose.sh" ps > "$TEST_ROOT/output" 2>&1; then
    printf 'FAIL: missing src/.env was accepted\n' >&2
    exit 1
fi

grep -F 'scripts/setup.sh' "$TEST_ROOT/output" >/dev/null

printf 'PASS: compose wrapper uses src/.env from the repository root.\n'
