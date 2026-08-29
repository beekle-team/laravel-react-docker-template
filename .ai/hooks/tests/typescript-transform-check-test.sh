#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
FAKE_BIN="$TMP_ROOT/bin"
DOCKER_LOG="$TMP_ROOT/docker.log"

mkdir -p \
  "$REPO/src/app/Data" \
  "$REPO/src/app/ValueObjects" \
  "$REPO/src/resources/js/types" \
  "$FAKE_BIN"
touch "$REPO/docker-compose.yml"
printf 'export {};\n' > "$REPO/src/resources/js/types/generated.d.ts"

cat > "$FAKE_BIN/docker" <<'DOCKER'
#!/usr/bin/env bash
set -euo pipefail

printf '%s\n' "$*" >> "${HOOK_TEST_DOCKER_LOG:?}"

case "$*" in
  *" ps --status running --services"*) printf 'app\n' ;;
  *" exec -T app php artisan typescript:transform"*)
    printf 'export {};\n' > "${HOOK_TEST_REPO:?}/src/resources/js/types/generated.d.ts"
    ;;
esac
DOCKER
chmod +x "$FAKE_BIN/docker"

cat > "$FAKE_BIN/npm" <<'NPM'
#!/usr/bin/env bash
set -euo pipefail
exit 0
NPM
chmod +x "$FAKE_BIN/npm"

git -C "$REPO" init -q
git -C "$REPO" config user.email hook-test@example.com
git -C "$REPO" config user.name 'Hook Test'

printf '<?php\nfinal class UserData {}\n' > "$REPO/src/app/Data/UserData.php"
printf '<?php\n#[TypeScript]\nfinal class Money {}\n' > "$REPO/src/app/ValueObjects/Money.php"
git -C "$REPO" add .
git -C "$REPO" commit -qm initial

run_hook() {
  PATH="$FAKE_BIN:$PATH" \
  HOOK_TEST_DOCKER_LOG="$DOCKER_LOG" \
  HOOK_TEST_REPO="$REPO" \
  CLAUDE_PROJECT_DIR="$REPO" \
  bash "$HOOK_DIR/pre-commit-check.sh" 2>&1
}

assert_generation_ran() {
  local description="$1"
  local output="$2"

  if ! grep -Fq 'exec -T app php artisan typescript:transform' "$DOCKER_LOG"; then
    printf 'FAIL: %s did not regenerate TypeScript types.\n%s\nDocker calls:\n' "$description" "$output" >&2
    cat "$DOCKER_LOG" >&2
    exit 1
  fi
}

printf '<?php\nfinal class UserData { public string $name; }\n' > "$REPO/src/app/Data/UserData.php"
git -C "$REPO" add src/app/Data/UserData.php
: > "$DOCKER_LOG"

set +e
OUTPUT="$(run_hook)"
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
  printf 'FAIL: hook exited with status %s.\n%s\n' "$STATUS" "$OUTPUT" >&2
  exit 1
fi

assert_generation_ran 'Data change' "$OUTPUT"
printf 'PASS: Data changes regenerate TypeScript types before commit.\n'

git -C "$REPO" reset --hard -q HEAD
printf '<?php\n#[TypeScript]\nfinal class Money { public int $amount; }\n' > "$REPO/src/app/ValueObjects/Money.php"
git -C "$REPO" add src/app/ValueObjects/Money.php
: > "$DOCKER_LOG"

set +e
OUTPUT="$(run_hook)"
STATUS=$?
set -e

if [ "$STATUS" -ne 0 ]; then
  printf 'FAIL: hook exited with status %s.\n%s\n' "$STATUS" "$OUTPUT" >&2
  exit 1
fi

assert_generation_ran 'transformable app PHP change' "$OUTPUT"
printf 'PASS: transformable PHP changes anywhere under app regenerate TypeScript types.\n'

git -C "$REPO" reset --hard -q HEAD
printf 'manual generated edit\n' > "$REPO/src/resources/js/types/generated.d.ts"
git -C "$REPO" add src/resources/js/types/generated.d.ts
: > "$DOCKER_LOG"

set +e
OUTPUT="$(run_hook)"
STATUS=$?
set -e

if [ "$STATUS" -eq 0 ]; then
  printf 'FAIL: a manual generated type edit bypassed regeneration.\n%s\nDocker calls:\n' "$OUTPUT" >&2
  cat "$DOCKER_LOG" >&2
  exit 1
fi

if ! grep -Fq 'generated TypeScript types are out of date' <<< "$OUTPUT"; then
  printf 'FAIL: generated type edit failed for the wrong reason.\n%s\n' "$OUTPUT" >&2
  exit 1
fi

printf 'PASS: manual generated type edits are blocked before commit.\n'
