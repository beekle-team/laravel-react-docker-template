#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
FAKE_BIN="$TMP_ROOT/bin"
DOCKER_LOG="$TMP_ROOT/docker.log"

mkdir -p "$REPO/src/app/Data" "$REPO/src/resources/js/types" "$FAKE_BIN"
touch "$REPO/docker-compose.yml"
printf 'export {};\n' > "$REPO/src/resources/js/types/generated.d.ts"

cat > "$FAKE_BIN/docker" <<'DOCKER'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${HOOK_TEST_DOCKER_LOG:?}"

case "$*" in
  *" ps --status running --services"*) printf 'app\n' ;;
esac
DOCKER
chmod +x "$FAKE_BIN/docker"

git -C "$REPO" init -q
git -C "$REPO" config user.email hook-test@example.com
git -C "$REPO" config user.name 'Hook Test'

printf '<?php\nfinal class UserData {}\n' > "$REPO/src/app/Data/UserData.php"
git -C "$REPO" add .
git -C "$REPO" commit -qm initial

printf '<?php\nfinal class UserData { public string $name; }\n' > "$REPO/src/app/Data/UserData.php"
git -C "$REPO" add src/app/Data/UserData.php
: > "$DOCKER_LOG"

set +e
OUTPUT="$(
  PATH="$FAKE_BIN:$PATH" \
  HOOK_TEST_DOCKER_LOG="$DOCKER_LOG" \
  CLAUDE_PROJECT_DIR="$REPO" \
  bash "$HOOK_DIR/pre-commit-check.sh" 2>&1
)"
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
  printf 'FAIL: hook exited with status %s.\n%s\n' "$STATUS" "$OUTPUT" >&2
  exit 1
fi

if ! grep -Fq 'exec -T app php artisan typescript:transform' "$DOCKER_LOG"; then
  printf 'FAIL: Data change did not regenerate TypeScript types.\n%s\nDocker calls:\n' "$OUTPUT" >&2
  cat "$DOCKER_LOG" >&2
  exit 1
fi

printf 'PASS: Data changes regenerate TypeScript types before commit.\n'
