---
description: Verify App
allowed-tools: Bash, Read, Edit, Glob, Grep, Task
argument-hint: [--quick]
---

# Verify App

プロジェクト全体の検証を並列実行し、問題があれば修正してください。

## オプション

- `--quick` または `-q`: Lint のみ（テストをスキップ）

## 実行方法

### 並列サブエージェント方式

Backend と Frontend の検証を**並列**で実行するため、2つの `quality-engineer` サブエージェントを同時起動する。

```
# 並列で2つのTask呼び出しを行う
Task(
  subagent_type: "quality-engineer",
  description: "Backend verification",
  prompt: "Verify Laravel backend:
    1. Run: composer lint (Pint + PHPStan + Rector)
    2. Run: composer test (Pest)
    3. Report: lint errors, test failures, coverage stats
    4. Fix auto-fixable issues with: composer pint",
  run_in_background: true
)

Task(
  subagent_type: "quality-engineer",
  description: "Frontend verification",
  prompt: "Verify React frontend:
    1. Run: npm run lint:js (Biome)
    2. Run: npm run types (TypeScript check)
    3. Run: npm run lint:react-compiler (React Compiler)
    4. Run: npm run lint:dead-code / npm run lint:duplication (knip / jscpd)
    5. Run: npm run test:unit (Vitest)
    6. Report: lint errors, type errors, test failures
    7. Fix auto-fixable issues",
  run_in_background: true
)
```

### --quick モード（Lintのみ）

`$ARGUMENTS` に `--quick` または `-q` が含まれる場合、テストをスキップ:

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

### 結果集約

TaskOutputで両方の結果を取得し、統合レポートを生成。

## 検証コマンド

### Backend (Laravel/PHP)
```bash
composer lint      # Pint + PHPStan + Rector dry-run
composer pint      # コードフォーマット
composer stan      # 静的解析
composer rector    # Rector dry-run
composer test      # Pest テスト
```

### Frontend (React/TypeScript)
```bash
npm run lint:js               # Biome lint
npm run types                 # TypeScript 型チェック
npm run lint:react-compiler   # React Compiler 最適化スキップ検出
npm run lint:dead-code        # knip
npm run lint:duplication      # jscpd
npm run test:unit             # Vitest
npm run test:e2e              # Playwright E2E
npm run format                # Biome フォーマット
```

### Full Stack
```bash
composer dev            # 開発サーバー起動（Laravel + Vite + Queue）
composer lint           # Pint + PHPStan + Rector (dry-run)
npm run lint:architecture   # knip + jscpd
```

## カバレッジ基準

- 新規コードは**テスト必須**
- カバレッジが下がっていたら警告
- 未テストのロジックを報告

## 重要

- すべてのテストがパスするまで完了としない
- 警告も可能な限り解消する
- 修正後は再度検証を実行して確認
- **並列実行**で高速化（BackendとFrontendは独立）
