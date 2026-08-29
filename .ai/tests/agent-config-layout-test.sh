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

EXPECTED_SKILLS=(
  backend-guidelines brand-guidelines dry-check frontend-design inertia-react
  tdd-methodology bdd commit review simplify verify
)

expected_skill_names="$(printf '%s\n' "${EXPECTED_SKILLS[@]}" | sort)"
actual_skill_names="$(find "$PROJECT_ROOT/.ai/skills" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort)"
[ "$actual_skill_names" = "$expected_skill_names" ] || fail "unexpected shared skill set:
$actual_skill_names"

for skill in "${EXPECTED_SKILLS[@]}"; do
  skill_file="$PROJECT_ROOT/.ai/skills/$skill/SKILL.md"
  [ -f "$skill_file" ] || fail "missing skill: $skill"
  grep -Eq "^name: $skill$" "$skill_file" || fail "name does not match directory: $skill"
  grep -Eq '^description: ' "$skill_file" || fail "missing description: $skill"
  [ "$(wc -l < "$skill_file")" -le 500 ] || fail "SKILL.md exceeds 500 lines: $skill"
done

[ ! -d "$PROJECT_ROOT/.claude/commands" ] || fail ".claude/commands must not contain shared workflows"

if grep -RInE 'Task\(|\$ARGUMENTS|allowed-tools:' "$PROJECT_ROOT/.ai/skills"; then
  fail "tool-specific syntax found in shared skills"
fi

if grep -RInE 'tightenco/ziggy|@radix-ui|laravel-precognition-react|resources/types/generated\.d\.ts' \
  "$PROJECT_ROOT/.ai/skills"; then
  fail "shared skills reference packages or generated paths that this repository does not use"
fi

if grep -RInE 'composer require --dev sebastian/phpcpd|npm install -g jscpd|vendor/bin/phpcpd' \
  "$PROJECT_ROOT/.ai/skills"; then
  fail "shared skills recommend undeclared duplication tools"
fi

if grep -RInE 'tests/Browser|tasks\.md' "$PROJECT_ROOT/.ai/skills"; then
  fail "shared skills reference unsupported test or task locations"
fi

BACKEND_GUIDE="$PROJECT_ROOT/.ai/skills/backend-guidelines/references/guide.md"
while IFS= read -r package; do
  if ! grep -Fq "\"$package\"" "$PROJECT_ROOT/src/composer.json" \
    && ! grep -Fq "\"$package\"" "$PROJECT_ROOT/src/package.json"; then
    fail "backend guide references an undeclared package: $package"
  fi
done < <(
  sed -n '/^## 主要ライブラリ$/,/^## Laravel Data/p' "$BACKEND_GUIDE" \
    | sed -n 's/^| `\([^`]*\)` |.*/\1/p'
)

GENERATED_TYPES_PATHS="$(grep -oE '[[:alnum:]_./-]+/generated\.d\.ts' "$BACKEND_GUIDE" | sort -u || true)"
[ -n "$GENERATED_TYPES_PATHS" ] || fail "backend guide does not identify the generated TypeScript declaration"
while IFS= read -r generated_types_path; do
  [ -f "$PROJECT_ROOT/$generated_types_path" ] \
    || fail "backend guide points to a missing generated TypeScript declaration: $generated_types_path"
done <<< "$GENERATED_TYPES_PATHS"

duplicate_names="$(find "$PROJECT_ROOT/.ai/skills" -name SKILL.md -exec sed -n 's/^name: //p' {} \; | sort | uniq -d)"
[ -z "$duplicate_names" ] || fail "duplicate skill names: $duplicate_names"

[ ! -d "$PROJECT_ROOT/.claude/hooks" ] || fail ".claude/hooks must not contain shared hook bodies"
assert_file .codex/config.toml

grep -Fq '[mcp_servers.laravel-boost]' "$PROJECT_ROOT/.codex/config.toml" \
  || fail "Codex config does not declare MCP server: laravel-boost"
grep -Fq 'command = "docker"' "$PROJECT_ROOT/.codex/config.toml" \
  || fail "Codex laravel-boost MCP does not use Docker"
grep -Fq 'args = ["compose", "exec", "-T", "app", "php", "artisan", "boost:mcp"]' \
  "$PROJECT_ROOT/.codex/config.toml" \
  || fail "Codex laravel-boost MCP command does not match the repository container"

for hook_path in auto-format.sh post-edit-check.sh pre-bash-check.sh; do
  grep -Fq ".ai/hooks/$hook_path" "$PROJECT_ROOT/.codex/config.toml" \
    || fail "Codex config does not reference shared hook: $hook_path"
  grep -Fq ".ai/hooks/$hook_path" "$PROJECT_ROOT/.claude/settings.json" \
    || fail "Claude settings do not reference shared hook: $hook_path"
done

if grep -Fq '.claude/hooks' "$PROJECT_ROOT/.claude/settings.json"; then
  fail "Claude settings still reference .claude/hooks"
fi

ACTIVE_OLD_REFERENCES="$(
  cd "$PROJECT_ROOT"
  git grep -n -E '\.claude/(rules|hooks|commands)/' -- \
    AGENTS.md CLAUDE.md .ai .codex docs/specs src/tests .github \
    ':(exclude)docs/superpowers/**' \
    ':(exclude).ai/tests/agent-config-layout-test.sh' || true
)"
[ -z "$ACTIVE_OLD_REFERENCES" ] || fail "active Claude-only references remain:
$ACTIVE_OLD_REFERENCES"

printf 'PASS: shared AI-agent configuration layout is valid.\n'
