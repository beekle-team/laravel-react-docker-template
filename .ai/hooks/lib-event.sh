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

event_normalize_repo_path() {
  local project_root="$1"
  local path="$2"

  case "$path" in
    "$project_root"/*)
      path="${path#"$project_root"/}"
      ;;
    /*)
      return
      ;;
  esac

  path="${path#./}"
  case "/$path/" in
    */../* | */./*)
      return
      ;;
  esac

  [ -n "$path" ] && printf '%s\n' "$path"
}

event_repo_paths() {
  local input="$1"
  local project_root="$2"
  local file_path

  file_path="$(printf '%s' "$input" | jq -r '.tool_input.file_path // empty')"

  if [ -n "$file_path" ]; then
    event_normalize_repo_path "$project_root" "$file_path"
    return
  fi

  printf '%s' "$input" \
    | jq -r '.tool_input.command // empty' \
    | sed -nE \
      -e 's/^\*\*\* (Add|Update|Delete) File: (.+)$/\2/p' \
      -e 's/^\*\*\* Move to: (.+)$/\1/p' \
    | while IFS= read -r path; do
        event_normalize_repo_path "$project_root" "$path"
      done \
    | awk '!seen[$0]++'
}
