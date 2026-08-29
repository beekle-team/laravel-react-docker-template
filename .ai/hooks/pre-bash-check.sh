#!/bin/bash
# 対応する AI エージェント向け PreToolUse(Bash) dispatcher。
# hook matcher はツール名を対象とするため、実際のコマンド判定をここで行う。

INPUT=$(cat)
COMMAND=$(printf '%s' "$INPUT" | jq -r '.tool_input.command // empty')
HOOK_DIR="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=lib-event.sh
source "$HOOK_DIR/lib-event.sh"
AI_PROJECT_ROOT="$(event_project_root "$INPUT")"
export AI_PROJECT_ROOT

# git commit 以外の Bash は素通し（lint / test を毎回走らせない）。
if ! printf '%s' "$COMMAND" | grep -qE '(^|[;&|]|\s)git(\s+-[^;&|]*)?\s+commit(\s|$)'; then
  exit 0
fi

printf '%s' "$INPUT" | "$HOOK_DIR/pre-commit-check.sh"
exit $?
