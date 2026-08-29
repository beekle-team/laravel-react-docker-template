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

event_path_is_within_root() {
  local project_root="$1"
  local path="$2"
  local root_real
  local probe
  local probe_real
  local parent

  # A real hook project root always exists. Keep lexical-only normalization for
  # synthetic inputs so callers can still parse events before a checkout exists.
  [ -d "$project_root" ] || return 0

  root_real="$(cd "$project_root" 2>/dev/null && pwd -P)" || return 1
  probe="$project_root/$path"

  # New files do not exist yet. Resolve their nearest existing ancestor so a
  # symlinked directory cannot escape the repository boundary.
  while [ ! -e "$probe" ] && [ ! -L "$probe" ]; do
    parent="${probe%/*}"
    [ "$parent" != "$probe" ] || return 1
    probe="$parent"
  done

  probe_real="$(realpath "$probe" 2>/dev/null)" || return 1
  case "$probe_real" in
    "$root_real" | "$root_real"/*)
      return 0
      ;;
  esac

  return 1
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

  [ -n "$path" ] \
    && event_path_is_within_root "$project_root" "$path" \
    && printf '%s\n' "$path"
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
