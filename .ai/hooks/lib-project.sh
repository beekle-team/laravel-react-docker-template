#!/bin/bash
# Shared project helpers for AI-agent hooks.
#
# Layout note: the Laravel app lives in src/, not at the repository root.
# vendor/ and node_modules/ are under src/, and the host has no php binary,
# so PHP tooling has to go through the app container (working_dir /var/www == ./src).

PROJECT_ROOT="${AI_PROJECT_ROOT:-${PROJECT_ROOT:-${CLAUDE_PROJECT_DIR:-$(pwd)}}}"
APP_DIR="$PROJECT_ROOT/src"
COMPOSE_FILE="$PROJECT_ROOT/docker-compose.yml"

# Repository-relative path (src/app/Foo.php) from an absolute or relative path.
repo_path() {
  local path="$1"
  printf '%s' "${path#"$PROJECT_ROOT"/}"
}

# Container-relative path (app/Foo.php) for a repo path under src/.
container_path() {
  local path
  path="$(repo_path "$1")"
  printf '%s' "${path#src/}"
}

# True when the app container is up and PHP tooling can be reached.
php_tooling_available() {
  command -v docker >/dev/null 2>&1 || return 1
  [ -f "$COMPOSE_FILE" ] || return 1
  docker compose -f "$COMPOSE_FILE" ps --status running --services 2>/dev/null | grep -qx app
}

# Run a command inside the app container from /var/www.
php_exec() {
  docker compose -f "$COMPOSE_FILE" exec -T app "$@"
}
