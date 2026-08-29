# AI エージェント設定全面共通化 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Claude Code と Codex の rules、skills、commands、hooks を `.ai/` の単一正本へ全面移行し、両エージェントで同じ規約と品質ガードを自動利用できる状態にして PR 作成後のレビューまで完了する。

**Architecture:** 共通本文は `.ai/rules`、`.ai/skills`、`.ai/hooks` に置き、Claude Code の `.claude/rules` / `.claude/skills` と Codex の `.agents/skills` は symlink で接続する。tool 固有の lifecycle 設定だけを `.claude/settings.json` と `.codex/config.toml` に残し、両方から同じ hook 実装を呼ぶ。構成契約と hook event 正規化を shell test で固定する。

**Tech Stack:** Markdown、Agent Skills (`SKILL.md`)、Bash、jq、Git symlink、Claude Code hooks、Codex hooks、GitHub Actions

**Spec:** `docs/superpowers/specs/2026-08-29-shared-ai-agent-configuration-design.md`

## Global Constraints

- AI エージェント共通の rule、skill、hook 本文は `.ai/**` だけを正本とする。
- `.claude/**` と `.codex/**` には tool 固有設定、README、共通正本への接続だけを置く。
- `.claude/rules -> ../.ai/rules`、`.claude/skills -> ../.ai/skills`、`.agents/skills -> ../.ai/skills` とする。
- 共通 skill は Agent Skills 形式とし、`SKILL.md` を 500 行以内に保つ。
- 共通 skill に Claude Code 固有の `Task(...)`、`$ARGUMENTS`、permission 記法を残さない。
- 個人用で git 管理外の `.claude/settings.local.json` は変更しない。
- 過去の `docs/superpowers/specs/**` と `docs/superpowers/plans/**` に記録された旧パスは一括置換しない。
- generated TypeScript と Wayfinder 生成物は手編集しない。

---

## File Structure

- `.ai/tests/agent-config-layout-test.sh`: 正本、symlink、skill metadata、tool 固有本文の不在、active path 参照を検証する構成契約。
- `.ai/rules/**`: 既存 `.ai/rules/**` と `.claude/rules/**` を統合した全規約の正本。
- `.ai/skills/*/SKILL.md`: 11 個の共通 skill の短い入口。
- `.ai/skills/*/references/**`: 長大な既存ガイドと例を progressive disclosure で保持する参照資料。
- `.ai/hooks/lib-project.sh`: repository root、app directory、Docker 実行の共通 helper。
- `.ai/hooks/lib-event.sh`: Claude Code / Codex hook JSON を repository-relative file path 一覧へ正規化する helper。
- `.ai/hooks/auto-format.sh`: 正規化された編集対象を Pint / Biome で format する best-effort hook。
- `.ai/hooks/post-edit-check.sh`: 正規化された全編集対象へ architecture guard と informational lint を適用する hook。
- `.ai/hooks/pre-bash-check.sh`: `git commit` だけを pre-commit 品質ゲートへ dispatch する hook。
- `.ai/hooks/pre-commit-check.sh`: staged diff に応じた blocking quality gate。
- `.ai/hooks/read-lints.sh`: 明示されたファイルの lint utility。
- `.ai/hooks/tests/**`: hook の既存回帰テストと Claude/Codex event 正規化テスト。
- `.claude/settings.json`: Claude Code lifecycle matcher と `.ai/hooks/**` の接続。
- `.codex/config.toml`: Codex lifecycle matcher と `.ai/hooks/**` の接続。
- `.github/workflows/hooks.yml`: 共通構成テストと hook 回帰テストの CI entry。
- `AGENTS.md`: Codex が対象別 `.ai/rules/**` を読むための共通入口。
- `CLAUDE.md`: `@AGENTS.md` を import する Claude Code の薄い入口。

---

### Task 1: Rules を `.ai/` の正本へ移す

**Files:**
- Create: `.ai/tests/agent-config-layout-test.sh`
- Move: `.claude/rules/frontend/**` → `.ai/rules/frontend/**`
- Move: `.claude/rules/laravel/**` → `.ai/rules/laravel/**`
- Move: `.claude/rules/testing/**` → `.ai/rules/testing/**`
- Move: `.claude/rules/php.md` → `.ai/rules/php.md`
- Move: `.claude/rules/type-safety.md` → `.ai/rules/type-safety.md`
- Replace: `.claude/rules` directory with symlink to `../.ai/rules`
- Modify: `.ai/rules/workspace.md`

**Interfaces:**
- Consumes: existing `.ai/rules/{workspace,testing,error-handling}.md` and `.claude/rules/**`.
- Produces: `.ai/rules/**` as the only rule body and `.claude/rules` as Claude Code discovery adapter.

- [ ] **Step 1: Write the failing rule-layout contract**

Create `.ai/tests/agent-config-layout-test.sh` with strict shell options, Git-root resolution, assertion helpers, the expected 19 rule files, and the symlink contract:

```bash
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
printf 'PASS: shared rule layout is valid.\n'
```

- [ ] **Step 2: Run the contract and verify RED**

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: FAIL on `.ai/rules/php.md` or `.claude/rules` not being a symlink.

- [ ] **Step 3: Move every rule body and create the Claude adapter**

Use `git mv` for all 16 files currently below `.claude/rules/**`, remove the empty directory, then create the relative symlink:

```bash
ln -s ../.ai/rules .claude/rules
```

Replace every rule frontmatter key named `globs` with the current Claude Code key `paths`, preserving its patterns. Update `.ai/rules/workspace.md` so its Laravel detail link is `.ai/rules/laravel/` and `.ai/rules/php.md`.

- [ ] **Step 4: Run the rule contract and inspect the symlink**

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: PASS.

Run: `git ls-files -s .claude/rules .ai/rules`

Expected: `.claude/rules` has Git mode `120000`; rule bodies are tracked below `.ai/rules/**`.

- [ ] **Step 5: Commit the rule migration**

```bash
git add .ai/rules .ai/tests/agent-config-layout-test.sh .claude/rules
git commit -m "chore: AI共通ルールを.aiへ集約する"
```

---

### Task 2: Existing Skills を共通 Agent Skills に移す

**Files:**
- Move: `.claude/skills/**` → `.ai/skills/**`
- Replace: `.claude/skills` directory with symlink to `../.ai/skills`
- Create: `.agents/skills` symlink to `../.ai/skills`
- Create: `.ai/skills/backend-guidelines/references/guide.md`
- Create: `.ai/skills/dry-check/references/guide.md`
- Create: `.ai/skills/inertia-react/references/guide.md`
- Create: `.ai/skills/tdd-methodology/references/guide.md`
- Modify: all six existing `.ai/skills/*/SKILL.md`
- Modify: `.ai/tests/agent-config-layout-test.sh`

**Interfaces:**
- Consumes: Task 1 layout helpers and `.ai/rules/**` paths.
- Produces: six portable project skills discoverable from both `.claude/skills` and `.agents/skills`.

- [ ] **Step 1: Extend the layout contract and verify RED**

Add both symlink assertions and metadata checks:

```bash
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
```

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: FAIL because `.ai/skills` and its adapters do not exist.

- [ ] **Step 2: Move the skills and create both native discovery adapters**

Move the tracked skill directory to `.ai/skills`, then create:

```bash
mkdir -p .agents
ln -s ../.ai/skills .claude/skills
ln -s ../.ai/skills .agents/skills
```

Keep `brand-guidelines/LICENSE.txt` and `frontend-design/LICENSE.txt` beside their skills.

- [ ] **Step 3: Convert long entrypoints to progressive disclosure**

For `backend-guidelines`, `dry-check`, `inertia-react`, and `tdd-methodology`, move the existing detailed body below its title into `references/guide.md`. Use these exact frontmatter values:

```yaml
---
name: backend-guidelines
description: Use when implementing or reviewing Laravel backend code that must keep controllers thin, place domain behavior in Eloquent or Gateway models, and use Concerns and query scopes consistently.
license: MIT
---
```

```yaml
---
name: dry-check
description: Use when detecting or removing duplicated PHP, Laravel, React, or TypeScript code while avoiding premature or behavior-changing abstractions.
license: MIT
---
```

```yaml
---
name: inertia-react
description: Use when building Laravel and React behavior with Inertia, Laravel Data generated types, forms, navigation, Precognition, deferred props, polling, prefetching, or infinite scroll.
license: MIT
---
```

```yaml
---
name: tdd-methodology
description: Use when implementing behavior with test-first development, Gherkin requirements, Pest Feature tests using scenario(), Vitest, or Playwright.
---
```

After the frontmatter, use this exact common body in each of the four entrypoints:

```markdown
# Workflow

## Required project rules

Read the relevant files under `.ai/rules/**` before making changes.

## Workflow

1. Identify the sections needed for the request.
2. Read those sections in `references/guide.md` completely.
3. Apply the repository rules and the guide together.
4. Run the quality gates required by `AGENTS.md`.

## Reference routing

- Use `references/guide.md` for the detailed patterns, examples, commands, and checklists.
```

Prepend a skill-specific list of required rules to the common body: `backend-guidelines` reads `.ai/rules/php.md` and `.ai/rules/laravel/**`; `dry-check` reads `.ai/rules/laravel/model-layer-boundaries.md` and `.ai/rules/frontend/architecture.md`; `inertia-react` reads `.ai/rules/frontend/**`, `.ai/rules/laravel/inertia-props.md`, and `.ai/rules/type-safety.md`; `tdd-methodology` reads `.ai/rules/testing.md`, `.ai/rules/frontend/testing.md`, and `.ai/rules/testing/architecture-tests.md`. Keep `brand-guidelines` and `frontend-design` as concise entrypoints and only update stale `.claude/rules/**` links to `.ai/rules/**`.

- [ ] **Step 4: Validate both discovery trees and entrypoint sizes**

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: PASS for six skills.

Run: `find -L .claude/skills .agents/skills -name SKILL.md -print | sort`

Expected: each adapter resolves the same six skill entrypoints.

- [ ] **Step 5: Commit the existing-skill migration**

```bash
git add .ai/skills .ai/tests/agent-config-layout-test.sh .claude/skills .agents/skills
git commit -m "chore: 既存skillをAIエージェント間で共有する"
```

---

### Task 3: Claude Commands を portable Skills に変換する

**Files:**
- Create: `.ai/skills/bdd/SKILL.md`
- Create: `.ai/skills/commit/SKILL.md`
- Create: `.ai/skills/review/SKILL.md`
- Create: `.ai/skills/simplify/SKILL.md`
- Create: `.ai/skills/verify/SKILL.md`
- Delete: `.claude/commands/bdd.md`
- Delete: `.claude/commands/commit.md`
- Delete: `.claude/commands/review.md`
- Delete: `.claude/commands/simplify.md`
- Delete: `.claude/commands/verify.md`
- Modify: `.ai/tests/agent-config-layout-test.sh`

**Interfaces:**
- Consumes: Task 2 common skill discovery and `.ai/rules/testing.md`.
- Produces: eleven shared project skills and no Claude-only command body.

- [ ] **Step 1: Extend the skill contract and verify RED**

Replace `EXISTING_SKILLS` with `EXPECTED_SKILLS` containing all eleven names. Add uniqueness and portability assertions:

```bash
EXPECTED_SKILLS=(
  backend-guidelines brand-guidelines dry-check frontend-design inertia-react
  tdd-methodology bdd commit review simplify verify
)

[ ! -d "$PROJECT_ROOT/.claude/commands" ] || fail ".claude/commands must not contain shared workflows"

if rg -n 'Task\(|\$ARGUMENTS|allowed-tools:' "$PROJECT_ROOT/.ai/skills"; then
  fail "tool-specific syntax found in shared skills"
fi

duplicate_names="$(find "$PROJECT_ROOT/.ai/skills" -name SKILL.md -exec sed -n 's/^name: //p' {} \; | sort | uniq -d)"
[ -z "$duplicate_names" ] || fail "duplicate skill names: $duplicate_names"
```

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: FAIL because the five new skill directories are missing and `.claude/commands` still exists.

- [ ] **Step 2: Author the five portable skill entrypoints**

Use these exact names and trigger scopes:

```yaml
name: bdd
description: Use when defining or implementing a Laravel Feature behavior from Gherkin requirements under docs/specs, including scenario approval and one-scenario Red-Green-Refactor.
```

```yaml
name: commit
description: Use when the user asks to create a git commit; inspect the diff, run change-appropriate quality gates, protect secrets, and write a Conventional Commit message.
```

```yaml
name: review
description: Use when reviewing a branch, pull request, commit, or file set for correctness, security, architecture, type safety, regressions, and missing tests.
```

```yaml
name: simplify
description: Use when simplifying recently changed or explicitly selected code without changing behavior, while removing dead code, unnecessary nesting, duplication, and unclear naming.
```

```yaml
name: verify
description: Use when verifying the repository or a completed change with the quality gates required by AGENTS.md, including targeted repair and rerun of failed checks.
```

Rewrite the command procedures in tool-neutral imperative language. `bdd` must defer to `.ai/rules/testing.md`; `commit` and `verify` must defer to the Quality Gates in `AGENTS.md`; `review` must report findings ordered by severity with file and line evidence; `simplify` must prohibit behavior changes.

- [ ] **Step 3: Remove the obsolete command files**

Delete the five tracked `.claude/commands/*.md` files. Do not leave forwarding copies because `.claude/skills` already exposes the same names as slash-invocable skills.

- [ ] **Step 4: Validate eleven portable skills**

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: PASS with eleven unique skills, no Claude-specific command syntax, and no `.claude/commands` directory.

- [ ] **Step 5: Commit the command-to-skill conversion**

```bash
git add .ai/skills .ai/tests/agent-config-layout-test.sh
git add -A .claude/commands
git commit -m "chore: Claude commandを共通skillへ変換する"
```

---

### Task 4: Hook 実装を共通化して両エージェントへ接続する

**Files:**
- Move: `.claude/hooks/*.sh` → `.ai/hooks/*.sh`
- Move: `.claude/hooks/tests/*-test.sh` → `.ai/hooks/tests/*-test.sh`
- Create: `.ai/hooks/lib-event.sh`
- Create: `.ai/hooks/tests/hook-event-normalization-test.sh`
- Modify: `.ai/hooks/lib-project.sh`
- Modify: `.ai/hooks/auto-format.sh`
- Modify: `.ai/hooks/post-edit-check.sh`
- Modify: `.ai/hooks/pre-bash-check.sh`
- Modify: `.ai/hooks/pre-commit-check.sh`
- Modify: `.ai/hooks/read-lints.sh`
- Modify: `.claude/settings.json`
- Create: `.codex/config.toml`
- Modify: `.ai/tests/agent-config-layout-test.sh`
- Modify: `.github/workflows/hooks.yml`

**Interfaces:**
- Consumes: raw hook JSON on stdin and the Git repository containing its session `cwd`.
- Produces: `event_project_root JSON`, `event_repo_paths JSON`, and shared hook executables called by both tool configs.

- [ ] **Step 1: Write the failing event-normalization tests**

Create test fixtures for Claude and Codex and assert exact output:

```bash
CLAUDE_EVENT='{"cwd":"/repo","tool_name":"Edit","tool_input":{"file_path":"/repo/src/app/User.php"}}'
CODEX_EVENT='{"cwd":"/repo/src","tool_name":"apply_patch","tool_input":{"command":"*** Begin Patch\n*** Update File: src/app/User.php\n*** Add File: src/resources/js/new.ts\n*** End Patch"}}'

assert_lines \
  $'src/app/User.php' \
  "$(event_repo_paths "$CLAUDE_EVENT" /repo)"

assert_lines \
  $'src/app/User.php\nsrc/resources/js/new.ts' \
  "$(event_repo_paths "$CODEX_EVENT" /repo)"
```

The test must also create a temporary Git repository, set event `cwd` to its nested `src/`, and assert that `event_project_root` returns the repository root. An event without `file_path` or patch file headers must return an empty list without modifying any file.

Run: `bash .ai/hooks/tests/hook-event-normalization-test.sh`

Expected: FAIL because `.ai/hooks/lib-event.sh` does not exist.

- [ ] **Step 2: Move hook files and implement the event adapter**

Move the tracked hook tree to `.ai/hooks`. In `lib-event.sh`, implement:

```bash
event_project_root() {
  local input="$1"
  local event_cwd
  event_cwd="$(printf '%s' "$input" | jq -r '.cwd // empty')"
  local seed="${CLAUDE_PROJECT_DIR:-${event_cwd:-$(pwd)}}"
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
```

Source `lib-event.sh` and initialize `PROJECT_ROOT` / `APP_DIR` from the event in both edit hooks. Iterate over every normalized path; skip nonexistent deleted files for format and lint while still allowing the event to finish safely. If normalization returns no path, print `No supported edited files in hook input; skipping.` to stderr and exit 0 without running a formatter, linter, or file mutation.

- [ ] **Step 3: Point Claude Code at the common hooks**

Update `.claude/settings.json` commands to:

```text
"$CLAUDE_PROJECT_DIR"/.ai/hooks/auto-format.sh
"$CLAUDE_PROJECT_DIR"/.ai/hooks/post-edit-check.sh
"$CLAUDE_PROJECT_DIR"/.ai/hooks/pre-bash-check.sh
```

Keep the existing `Edit|Write` and `Bash` matchers and timeouts.

- [ ] **Step 4: Add equivalent trusted-project Codex hooks**

Create `.codex/config.toml` with `PostToolUse` matcher `Edit|Write` for `.ai/hooks/auto-format.sh` and `.ai/hooks/post-edit-check.sh`, and `PreToolUse` matcher `Bash` for `.ai/hooks/pre-bash-check.sh`. Each command must resolve the repository root from the hook process working directory before executing the common script, for example:

```toml
[[hooks.PreToolUse]]
matcher = "Bash"

[[hooks.PreToolUse.hooks]]
type = "command"
command = "bash -lc 'root=$(git rev-parse --show-toplevel) && exec \"$root/.ai/hooks/pre-bash-check.sh\"'"
timeout = 120
```

Use the same command pattern for both `PostToolUse` hook handlers with timeouts 10 and 30.

- [ ] **Step 5: Extend layout and CI contracts**

Assert `.claude/hooks` does not exist, `.codex/config.toml` contains all three common hook paths, and `.claude/settings.json` does not reference `.claude/hooks`. Update `.github/workflows/hooks.yml` to run:

```bash
bash .ai/tests/agent-config-layout-test.sh
for test_file in .ai/hooks/tests/*-test.sh; do
  bash "$test_file"
done
```

- [ ] **Step 6: Run all hook tests**

Run: `bash .ai/hooks/tests/hook-event-normalization-test.sh`

Expected: PASS.

Run: `for test_file in .ai/hooks/tests/*-test.sh; do bash "$test_file"; done`

Expected: every existing and new hook regression test passes.

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: PASS.

- [ ] **Step 7: Commit dual-agent hooks**

```bash
git add .ai/hooks .ai/tests .claude/settings.json .codex/config.toml .github/workflows/hooks.yml
git add -A .claude/hooks
git commit -m "chore: 品質hookをClaudeとCodexで共有する"
```

---

### Task 5: Entrypoints、active references、運用文書を統一する

**Files:**
- Modify: `AGENTS.md`
- Modify: `CLAUDE.md`
- Modify: `.ai/README.md`
- Modify: `.codex/README.md`
- Modify: `docs/specs/error-handling/requirements.md`
- Modify: `src/tests/Arch/CodingStandardsTest.php`
- Modify: `src/tests/Arch/LayerBoundariesTest.php`
- Modify: `src/tests/Arch/PrecognitionTest.php`
- Modify: `src/tests/PHPStan/Rules/ControllerValidationRule.php`
- Modify: `.ai/tests/agent-config-layout-test.sh`
- Modify: active `.ai/rules/**` and `.ai/skills/**` references as found by the contract

**Interfaces:**
- Consumes: final paths produced by Tasks 1–4.
- Produces: one common entry instruction and no active canonical reference to `.claude/rules/**`.

- [ ] **Step 1: Add the failing active-reference contract**

Search active files while excluding historical Superpowers documents, `.git`, worktrees, dependencies, and the layout test itself:

```bash
ACTIVE_OLD_REFERENCES="$(
  rg -n '\.claude/(rules|hooks|commands)' \
    AGENTS.md CLAUDE.md .ai .codex docs/specs src/tests .github \
    --glob '!docs/superpowers/**' \
    --glob '!.ai/tests/agent-config-layout-test.sh' || true
)"
[ -z "$ACTIVE_OLD_REFERENCES" ] || fail "active Claude-only references remain:\n$ACTIVE_OLD_REFERENCES"
```

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: FAIL and list `AGENTS.md`, source comments, current requirements, or skill references that still use old canonical paths.

- [ ] **Step 2: Make AGENTS.md the common entry instruction**

Keep the required `.ai/{README,rules/workspace,rules/testing,rules/error-handling}.md` list. Route Laravel/PHP to `.ai/rules/laravel/` and `.ai/rules/php.md`, React/TypeScript to `.ai/rules/frontend/` and `.ai/rules/type-safety.md`, and architecture tests to `.ai/rules/testing/`. Document that `.ai/skills/**` is discovered through each tool adapter and that generated TypeScript and Wayfinder artifacts are never hand-edited.

- [ ] **Step 3: Make CLAUDE.md a thin import**

Replace duplicated common instructions with:

```markdown
# CLAUDE.md

@AGENTS.md

## Claude Code 固有

- Path scoped rules は `.claude/rules` symlink から `.ai/rules/**` を読み込む。
- Project skills は `.claude/skills` symlink から `.ai/skills/**` を読み込む。
- Lifecycle hook の接続設定は `.claude/settings.json` に置く。
```

- [ ] **Step 4: Update shared and Codex documentation**

In `.ai/README.md`, document the three canonical content types and the three symlinks. In `.codex/README.md`, document `.agents/skills`, `.codex/config.toml`, trusted-project hook review with `/hooks`, and the same `.ai/**` canonical paths.

Update UC-07 in `docs/specs/error-handling/requirements.md` so its acceptance criterion says `.claude/rules` is only a symlink adapter and all rule bodies live under `.ai/rules/**`.

- [ ] **Step 5: Update source comments and all active internal links**

Replace current rule citations in `src/tests/Arch/**`, `src/tests/PHPStan/**`, `.ai/rules/**`, and `.ai/skills/**` with their `.ai/rules/**` paths. Do not rewrite the two historical Superpowers directories.

- [ ] **Step 6: Run the complete structure contract**

Run: `bash .ai/tests/agent-config-layout-test.sh`

Expected: PASS with no active Claude-only canonical references.

- [ ] **Step 7: Commit entrypoint and reference updates**

```bash
git add AGENTS.md CLAUDE.md .ai .codex docs/specs/error-handling/requirements.md src/tests
git commit -m "docs: AIエージェント共通設定の導線を統一する"
```

---

### Task 6: Full Verification と差分監査を完了する

**Files:**
- Modify: only files required to fix failures found by this task

**Interfaces:**
- Consumes: the completed migration and all repository quality gates.
- Produces: verified branch with no unstaged repair and an evidence set suitable for PR creation.

- [ ] **Step 1: Run shell and layout gates**

Run:

```bash
bash scripts/check-php-version-consistency.sh
bash .ai/tests/agent-config-layout-test.sh
for test_file in .ai/hooks/tests/*-test.sh; do bash "$test_file"; done
```

Expected: every command exits 0.

- [ ] **Step 2: Run backend quality gates**

Run:

```bash
docker compose exec app composer lint
docker compose exec app composer test
```

Expected: Pint, PHPStan, Rector dry-run, and Pest all pass.

- [ ] **Step 3: Audit the full diff against the specification**

Run:

```bash
git diff --check origin/main...HEAD
git diff --stat origin/main...HEAD
git status --short
git ls-files -s .claude/rules .claude/skills .agents/skills
```

Expected: no whitespace errors, only scoped changes, clean worktree, and all three links use mode `120000`.

Check every numbered acceptance condition in the spec against a file, test, or command result. Treat a missing or indirect result as incomplete and repair it before continuing.

- [ ] **Step 4: Commit verification repairs if needed**

If verification required changes, stage only those files and commit:

```bash
git commit -m "fix: AI共通設定の検証不備を解消する"
```

If no files changed, do not create an empty commit.

---

### Task 7: Pull Request を作成して PR 差分をレビューする

**Files:**
- Modify: only files required by review findings

**Interfaces:**
- Consumes: verified implementation branch from Task 6.
- Produces: pushed branch, open GitHub PR, completed post-creation review, and fixes for every confirmed finding.

- [ ] **Step 1: Push the isolated feature branch**

Run: `git push -u origin chore/shared-ai-agent-configuration`

Expected: remote tracking branch is created successfully.

- [ ] **Step 2: Create the PR**

Create the PR against `main` with title `chore: AIエージェント設定を全面共通化する`. The body must include Summary, Test Plan, symlink topology, Codex hook trust note, and the exact verification commands from Task 6.

Run:

```bash
gh pr create \
  --base main \
  --head chore/shared-ai-agent-configuration \
  --title "chore: AIエージェント設定を全面共通化する" \
  --body $'## Summary\n- rules、skills、hooks の正本を `.ai/` に集約\n- Claude Code と Codex の native discovery を symlink で同じ正本へ接続\n- 両エージェントの hook 入力と品質ゲートを共通化\n\n## Test Plan\n- `bash scripts/check-php-version-consistency.sh`\n- `bash .ai/tests/agent-config-layout-test.sh`\n- `for test_file in .ai/hooks/tests/*-test.sh; do bash "$test_file"; done`\n- `docker compose exec app composer lint`\n- `docker compose exec app composer test`\n\n## Notes\n- `.claude/rules`、`.claude/skills`、`.agents/skills` は `.ai/**` への symlink\n- Codex の project hooks は trusted project で `/hooks` から承認が必要'
```

Expected: GitHub returns the new PR URL.

- [ ] **Step 3: Review the created PR from GitHub state**

Run:

```bash
gh pr view --json number,url,title,baseRefName,headRefName,mergeStateStatus,statusCheckRollup
gh pr diff
```

Review the PR for correctness, security, symlink portability, Claude/Codex discovery behavior, hook input safety, stale references, test coverage, and accidental unrelated commits. Report findings by severity with file and line evidence; do not treat style-only observations as defects.

- [ ] **Step 4: Fix every confirmed review finding**

For each confirmed finding, add or strengthen a failing regression test, observe RED, implement the smallest correct fix, rerun the targeted test and Task 6 gates, commit, and push. Repeat the GitHub diff review until no Critical or Major finding remains.

- [ ] **Step 5: Record the review result and verify checks**

Post a concise PR comment containing the review result and verification commands. If findings were fixed, identify the fix commits. Then run:

```bash
gh pr checks --watch
gh pr view --json url,mergeStateStatus,statusCheckRollup
```

Expected: required checks finish successfully, or any external pending check is reported precisely without claiming completion.
