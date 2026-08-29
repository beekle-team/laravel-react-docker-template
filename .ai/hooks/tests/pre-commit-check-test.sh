#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

REPO="$TMP_ROOT/repo"
FAKE_BIN="$TMP_ROOT/bin"
DOCKER_LOG="$TMP_ROOT/docker.log"

mkdir -p "$REPO/src" "$FAKE_BIN"
touch "$REPO/docker-compose.yml"

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

printf '{"packages":[]}\n' > "$REPO/src/composer.lock"
git -C "$REPO" add src/composer.lock
git -C "$REPO" commit -qm initial

printf '{"packages":[{"name":"laravel/framework"}]}\n' > "$REPO/src/composer.lock"
git -C "$REPO" add src/composer.lock
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

if ! grep -Fq 'exec -T app ./vendor/bin/rector process --dry-run' "$DOCKER_LOG"; then
  printf 'FAIL: composer.lock-only change did not run Rector.\n%s\nDocker calls:\n' "$OUTPUT" >&2
  cat "$DOCKER_LOG" >&2
  exit 1
fi

printf 'PASS: composer.lock-only change runs version-aware Rector checks.\n'
