#!/bin/bash
# PreToolUse(Bash) のディスパッチャ。
#
# Claude Code の hook matcher は「ツール名」に対する正規表現で、
# permissions の "Bash(git commit:*)" 記法は使えない。matcher に
# コマンド条件を書くと一致せず hook が一度も起動しないため、
# matcher は "Bash" にして、実際のコマンド判定をここで行う。

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
