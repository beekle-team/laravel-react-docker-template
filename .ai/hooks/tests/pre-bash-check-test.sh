#!/usr/bin/env bash
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_ROOT="$(mktemp -d)"
trap 'rm -rf "$TMP_ROOT"' EXIT

FAKE_HOOK_DIR="$TMP_ROOT/hooks"
CALL_LOG="$TMP_ROOT/calls.log"
ERROR_LOG="$TMP_ROOT/errors.log"
mkdir -p "$FAKE_HOOK_DIR"
cp "$HOOK_DIR/pre-bash-check.sh" "$FAKE_HOOK_DIR/pre-bash-check.sh"
cp "$HOOK_DIR/lib-event.sh" "$FAKE_HOOK_DIR/lib-event.sh"

cat > "$FAKE_HOOK_DIR/pre-commit-check.sh" <<'HOOK'
#!/usr/bin/env bash
printf 'called\n' >> "${HOOK_TEST_CALL_LOG:?}"
HOOK
chmod +x "$FAKE_HOOK_DIR/pre-commit-check.sh"

printf '%s' '{"tool_input":{"command":"git status"}}' \
  | HOOK_TEST_CALL_LOG="$CALL_LOG" bash "$FAKE_HOOK_DIR/pre-bash-check.sh" 2>> "$ERROR_LOG"

if [ -s "$CALL_LOG" ]; then
  printf 'FAIL: a non-commit git command triggered the pre-commit checks.\n' >&2
  exit 1
fi

for command in \
  'git commit -m test' \
  'git -C "/tmp/repo" commit -m test' \
  'git -c user.name=test commit -m test'; do
  jq -cn --arg command "$command" '{tool_input: {command: $command}}' \
    | HOOK_TEST_CALL_LOG="$CALL_LOG" bash "$FAKE_HOOK_DIR/pre-bash-check.sh" 2>> "$ERROR_LOG"
done

if [ "$(wc -l < "$CALL_LOG" | tr -d ' ')" -ne 3 ]; then
  printf 'FAIL: supported git commit forms did not trigger the pre-commit checks exactly once each.\n' >&2
  exit 1
fi

if [ -s "$ERROR_LOG" ]; then
  printf 'FAIL: pre-bash dispatcher emitted unexpected stderr:\n' >&2
  cat "$ERROR_LOG" >&2
  exit 1
fi

printf 'PASS: Bash dispatch only intercepts git commit.\n'
