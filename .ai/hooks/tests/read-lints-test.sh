#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
FAKE_HOOK_DIR="$TMP_ROOT/hooks"
FAKE_BIN="$TMP_ROOT/bin"
mkdir -p "$REPO/src/resources/js" "$FAKE_HOOK_DIR" "$FAKE_BIN"
printf 'export {};\n' > "$REPO/src/resources/js/example.ts"

cp "$HOOK_DIR/read-lints.sh" "$FAKE_HOOK_DIR/read-lints.sh"
cp "$HOOK_DIR/lib-project.sh" "$FAKE_HOOK_DIR/lib-project.sh"

cat > "$FAKE_BIN/npm" <<'NPM'
#!/usr/bin/env bash
printf 'simulated type error\n' >&2
exit 7
NPM
chmod +x "$FAKE_BIN/npm"

set +e
OUTPUT="$(
  PATH="$FAKE_BIN:$PATH" AI_PROJECT_ROOT="$REPO" \
    bash "$FAKE_HOOK_DIR/read-lints.sh" "$REPO/src/resources/js/example.ts" 2>&1
)"
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  printf 'FAIL: read-lints masked a failing TypeScript check.\n%s\n' "$OUTPUT" >&2
  exit 1
fi

printf '%s' "$OUTPUT" | grep -Fq 'simulated type error' \
  || { printf 'FAIL: read-lints hid the TypeScript diagnostic.\n%s\n' "$OUTPUT" >&2; exit 1; }

printf 'PASS: read-lints propagates TypeScript failures.\n'
