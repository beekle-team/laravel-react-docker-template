---
name: verify
description: プロジェクト全体の検証を並列実行し、問題があれば修正する。Backend/Frontend を同時にチェック。
license: MIT
---

# Verify App

プロジェクト全体の品質検証を並列サブエージェントで実行するスキル。

**Keywords**: verify, lint, test, quality, pint, phpstan, biome, pest, vitest, parallel

---

## Usage

```
/verify           # フル検証（Lint + Test）
/verify --quick   # Lint のみ（テストをスキップ）
/verify -q        # 同上
```

---

## Workflow

### Step 1: モード判定

`$ARGUMENTS` に `--quick` または `-q` が含まれるか確認。

### Step 2: 並列サブエージェント起動

**フルモード** (デフォルト):

```
Task(
  subagent_type: "quality-engineer",
  description: "Backend verification",
  prompt: "Verify Laravel backend:
    1. Run: composer lint (Pint + PHPStan)
    2. Run: composer test (Pest)
    3. Report: lint errors, test failures, coverage stats
    4. Fix auto-fixable issues with: composer pint",
  run_in_background: true
)

Task(
  subagent_type: "quality-engineer",
  description: "Frontend verification",
  prompt: "Verify React frontend:
    1. Run: npm run lint (Biome + ESLint)
    2. Run: npm run types (TypeScript check)
    3. Run: npm run test (Vitest)
    4. Report: lint errors, type errors, test failures
    5. Fix auto-fixable issues",
  run_in_background: true
)
```

**Quick モード** (`--quick` / `-q`):

```
Task(
  subagent_type: "quality-engineer",
  description: "Quick lint check",
  prompt: "Quick lint check (no tests):
    - Backend: composer lint
    - Frontend: npm run lint && npm run types
    Report errors only, fix auto-fixable issues",
  run_in_background: false
)
```

### Step 3: 結果集約

`TaskOutput` で両方の結果を取得し、統合レポートを生成。

### Step 4: 問題修正

エラーがあれば修正し、再検証を実行。

---

## Commands

### Backend (Laravel/PHP)

```bash
composer lint      # Pint + PHPStan
composer pint      # コードフォーマット
composer stan      # 静的解析
composer test      # Pest テスト
```

### Frontend (React/TypeScript)

```bash
npm run lint       # Biome + ESLint
npm run lint:js    # Biome のみ
npm run types      # TypeScript 型チェック
npm run test       # Vitest テスト
npm run format     # Prettier フォーマット
```

### Full Stack

```bash
composer dev       # 開発サーバー起動（Laravel + Vite + Queue）
npm run lint:all   # JS + PHP 全体 lint
```

---

## Quality Standards

- 新規コードは**テスト必須**
- カバレッジが下がっていたら警告
- 未テストのロジックを報告
- すべてのテストがパスするまで完了としない
- 警告も可能な限り解消する
- 修正後は再度検証を実行して確認

---

## Output Format

```
## Verification Report

### Backend
- Lint: ✅ Passed / ❌ N errors
- Tests: ✅ M passed / ❌ N failed
- Coverage: XX%

### Frontend
- Lint: ✅ Passed / ❌ N errors
- Types: ✅ Passed / ❌ N errors
- Tests: ✅ M passed / ❌ N failed

### Summary
Overall: ✅ All checks passed / ❌ Action required
```
