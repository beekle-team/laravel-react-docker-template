#!/usr/bin/env bash
# Normalize supported Claude Code and Codex hook events.

event_project_root() {
  local input="$1"
  local event_cwd
  local seed

  event_cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
  seed="${CLAUDE_PROJECT_DIR:-${event_cwd:-$(pwd)}}"
  git -C "$seed" rev-parse --show-toplevel 2>/dev/null || printf '%s' "$seed"
}

event_repo_paths() {
  local input="$1"
  local project_root="$2"
  local file_path

  file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

  if [ -n "$file_path" ]; then
    printf '%s\n' "${file_path#"$project_root"/}"
    return
  fi

  printf '%s' "$input" \
    | jq -r '.tool_input.command // empty' \
    | sed -nE 's/^\*\*\* (Add|Update|Delete) File: (.+)$/\2/p' \
    | awk '!seen[$0]++'
}
