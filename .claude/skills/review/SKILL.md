---
name: review
description: 複数の専門エージェントで並列コードレビュー。セキュリティ・品質・アーキテクチャの観点から評価。
license: MIT
---

# Code Review

指定されたファイルまたは変更を**複数の専門エージェントで並列レビュー**するスキル。

**Keywords**: review, code-review, security, quality, architecture, parallel-agents

---

## Usage

```
/review                      # 現在のブランチ変更をレビュー
/review path/to/file.php     # 指定ファイルをレビュー
/review #123                  # PR #123 をレビュー
```

---

## Workflow

### Step 1: 対象特定

- `$ARGUMENTS` があれば、そのファイル/PRを対象
- なければ、現在のブランチの変更（`git diff main...HEAD`）を対象

### Step 2: 並列エージェントレビュー

3つの専門エージェントを**並列**で起動:

```
# 1. セキュリティレビュー
Task(
  subagent_type: "security-engineer",
  description: "Security review",
  prompt: "Review changes for security issues:
    - SQL injection (raw DB queries)
    - XSS (unescaped output in Blade/React)
    - CSRF (missing middleware)
    - Mass assignment (missing $fillable)
    - Authentication/authorization flaws
    - Secrets exposure
    Target: [変更ファイルリスト]",
  run_in_background: true
)

# 2. コード品質レビュー
Task(
  subagent_type: "refactoring-expert",
  description: "Quality review",
  prompt: "Review code quality:
    - Naming clarity
    - Single responsibility
    - Code duplication
    - N+1 query problems
    - Error handling
    - TypeScript type safety
    Target: [変更ファイルリスト]",
  run_in_background: true
)

# 3. アーキテクチャレビュー
Task(
  subagent_type: "system-architect",
  description: "Architecture review",
  prompt: "Review architecture alignment:
    - Laravel patterns (Fat Model, FormRequest, Concerns)
    - Controller simplicity (no business logic)
    - Query Scopes for readable queries
    - React component hierarchy
    - Design system compliance
    Target: [変更ファイルリスト]",
  run_in_background: true
)
```

### Step 3: 結果集約

`TaskOutput` で3つの結果を取得し、統合レポートを生成。

### Step 4: 問題優先度付け

- Critical (🔴): 即時対応必須
- Major (🟡): 修正推奨
- Minor (🟢): 改善提案

---

## Project-Specific Checkpoints

### Laravel Backend

- Route Model Binding 使用
- FormRequest でバリデーション
- Fat Model + Concerns でビジネスロジック
- Query Scopes で読みやすいクエリ
- Eager loading で N+1 防止

### React Frontend

- デザインシステム準拠
- TypeScript 型定義完備
- Inertia router 使用
- アクセシビリティ対応
- Dark mode サポート

---

## Output Format

```
## Code Review Summary

### Overview
- Files reviewed: N
- Issues found: X critical, Y major, Z minor

## Issues

### Critical (🔴)
- [security-engineer] SQL injection risk in UserController.php:45
- [refactoring-expert] N+1 query in OrderService.php:120

### Major (🟡)
- [system-architect] Business logic in controller, move to model
- [security-engineer] Missing authorization check on /api/admin

### Minor (🟢)
- [refactoring-expert] Variable naming could be clearer
- [system-architect] Missing TypeScript type for API response

## Suggestions
- Consider extracting common validation logic to a Concern
- Add Query Scope for frequently used filters

## Verdict
❌ Changes require fixes before merge
✅ Changes approved with minor suggestions
```
