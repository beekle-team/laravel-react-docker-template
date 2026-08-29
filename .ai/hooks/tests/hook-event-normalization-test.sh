#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# shellcheck source=../lib-event.sh
source "$HOOK_DIR/lib-event.sh"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_lines() {
  local expected="$1"
  local actual="$2"
  [ "$actual" = "$expected" ] || fail "expected [$expected], got [$actual]"
}

CLAUDE_EVENT='{"cwd":"/repo","tool_name":"Edit","tool_input":{"file_path":"/repo/src/app/User.php"}}'
CODEX_EVENT='{"cwd":"/repo/src","tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: src/app/User.php\n*** Add File: src/resources/js/new.ts\n*** End Patch"}}'

assert_lines \
  'src/app/User.php' \
  "$(event_repo_paths "$CLAUDE_EVENT" /repo)"

assert_lines \
  $'src/app/User.php\nsrc/resources/js/new.ts' \
  "$(event_repo_paths "$CODEX_EVENT" /repo)"

TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

mkdir -p "$TMP_ROOT/repo/src"
git -C "$TMP_ROOT/repo" init -q

ROOT_EVENT="$(jq -cn --arg cwd "$TMP_ROOT/repo/src" '{cwd: $cwd, tool_input: {}}')"
EXPECTED_ROOT="$(git -C "$TMP_ROOT/repo" rev-parse --show-toplevel)"
assert_lines "$EXPECTED_ROOT" "$(event_project_root "$ROOT_EVENT")"

printf 'unchanged\n' > "$TMP_ROOT/repo/sentinel.txt"
UNKNOWN_EVENT="$(jq -cn --arg cwd "$TMP_ROOT/repo" '{cwd: $cwd, tool_name: "unknown", tool_input: {}}')"
assert_lines '' "$(event_repo_paths "$UNKNOWN_EVENT" "$TMP_ROOT/repo")"

for edit_hook in auto-format.sh post-edit-check.sh; do
  HOOK_OUTPUT="$(printf '%s' "$UNKNOWN_EVENT" | bash "$HOOK_DIR/$edit_hook" 2>&1)"
  [ "$HOOK_OUTPUT" = 'No supported edited files in hook input; skipping.' ] \
    || fail "$edit_hook did not report a safe skip"
done

[ "$(cat "$TMP_ROOT/repo/sentinel.txt")" = 'unchanged' ] || fail 'unknown event modified a file'

printf 'PASS: Claude and Codex hook events normalize to repository paths.\n'
