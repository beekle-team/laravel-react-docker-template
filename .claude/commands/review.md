---
description: Code Review
allowed-tools: Bash, Read, Glob, Grep, Task
---

# Code Review

指定されたファイルまたは変更を**複数の専門エージェントで並列レビュー**します。

## 対象

$ARGUMENTS が指定されていれば、そのファイル/PRを対象にする。
指定がなければ、現在のブランチの変更（`git diff main...HEAD`）を対象にする。

## 実行方法

### 並列エージェントレビュー

3つの専門エージェントを**並列**で起動し、異なる観点からレビュー:

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

### 結果集約

TaskOutputで3つの結果を取得し、統合レポートを生成。

## 出力形式

```
## Summary
全体的な評価（3エージェントの総合）

## Issues
### Critical (🔴)
- [security-engineer] SQL injection risk in ...
- [refactoring-expert] N+1 query in ...

### Major (🟡)
- [system-architect] Business logic in controller ...
- [security-engineer] Missing authorization check ...

### Minor (🟢)
- [refactoring-expert] Variable naming ...
- [system-architect] Missing TypeScript type ...

## Suggestions
改善提案（各エージェントから）
```

## プロジェクト固有のチェックポイント

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
