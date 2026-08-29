#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(git rev-parse --show-toplevel)"

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_file() {
  [ -f "$PROJECT_ROOT/$1" ] || fail "missing file: $1"
}

assert_link() {
  local path="$1"
  local target="$2"
  [ -L "$PROJECT_ROOT/$path" ] || fail "not a symlink: $path"
  [ "$(readlink "$PROJECT_ROOT/$path")" = "$target" ] || fail "wrong symlink target: $path"
}

RULE_FILES=(
  .ai/rules/workspace.md
  .ai/rules/testing.md
  .ai/rules/error-handling.md
  .ai/rules/php.md
  .ai/rules/type-safety.md
  .ai/rules/frontend/architecture.md
  .ai/rules/frontend/biome.md
  .ai/rules/frontend/quality-scans.md
  .ai/rules/frontend/react-compiler.md
  .ai/rules/frontend/testing.md
  .ai/rules/laravel/form-request-validation.md
  .ai/rules/laravel/ide-helper.md
  .ai/rules/laravel/inertia-props.md
  .ai/rules/laravel/larastan.md
  .ai/rules/laravel/model-layer-boundaries.md
  .ai/rules/laravel/pint.md
  .ai/rules/laravel/rector.md
  .ai/rules/laravel/typescript-transform.md
  .ai/rules/testing/architecture-tests.md
)

for rule_file in "${RULE_FILES[@]}"; do
  assert_file "$rule_file"
done

assert_link .claude/rules ../.ai/rules

assert_link .claude/skills ../.ai/skills
assert_link .agents/skills ../.ai/skills

EXISTING_SKILLS=(
  backend-guidelines
  brand-guidelines
  dry-check
  frontend-design
  inertia-react
  tdd-methodology
)

for skill in "${EXISTING_SKILLS[@]}"; do
  skill_file="$PROJECT_ROOT/.ai/skills/$skill/SKILL.md"
  [ -f "$skill_file" ] || fail "missing skill: $skill"
  rg -q '^name: ' "$skill_file" || fail "missing name: $skill"
  rg -q '^description: ' "$skill_file" || fail "missing description: $skill"
  [ "$(wc -l < "$skill_file")" -le 500 ] || fail "SKILL.md exceeds 500 lines: $skill"
done

printf 'PASS: shared rule layout is valid.\n'
