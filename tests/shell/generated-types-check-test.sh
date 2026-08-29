#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd -P)"
TEST_ROOT="$(mktemp -d)"
trap 'rm -rf "$TEST_ROOT"' EXIT

mkdir -p "$TEST_ROOT/bin" "$TEST_ROOT/scripts" "$TEST_ROOT/resources/js/types"
cp "$PROJECT_ROOT/src/scripts/check-generated-types.sh" "$TEST_ROOT/scripts/check-generated-types.sh"

cat > "$TEST_ROOT/bin/php" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "${GENERATED_TYPES_CONTENT:?}" > resources/js/types/generated.d.ts
EOF
chmod +x "$TEST_ROOT/bin/php"

cd "$TEST_ROOT"
printf 'stable\n' > resources/js/types/generated.d.ts

GENERATED_TYPES_CONTENT=stable PATH="$TEST_ROOT/bin:$PATH" \
    bash scripts/check-generated-types.sh > current.out
grep -Fx 'Generated TypeScript types are current.' current.out >/dev/null

set +e
GENERATED_TYPES_CONTENT=changed PATH="$TEST_ROOT/bin:$PATH" \
    bash scripts/check-generated-types.sh > stale.out 2> stale.err
status=$?
set -e

if [[ "$status" -eq 0 ]]; then
    printf 'FAIL: stale generated types were accepted.\n' >&2
    exit 1
fi

grep -Fx 'Generated TypeScript types are out of date.' stale.err >/dev/null

printf 'PASS: generated types are checked without requiring a Git worktree.\n'
