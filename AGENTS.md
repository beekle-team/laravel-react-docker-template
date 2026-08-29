# AGENTS.md
このファイルは Codex の入口です。AIエージェント共通ルールの正本は .ai/ に置きます。
## 必読
- .ai/README.md
- .ai/rules/workspace.md
- .ai/rules/testing.md
- .ai/rules/error-handling.md
## 変更対象ごとの詳細ルール
- Laravel / PHP: .claude/rules/laravel/ と .claude/rules/php.md
- React / TypeScript: .claude/rules/frontend/ と .claude/rules/type-safety.md
- Test / static analysis: .claude/rules/testing/
## Codex固有
- Codex固有情報は .codex/ に置く。
- 共通ルールは .ai/ を更新する。
- generated TypeScript と Wayfinder生成物を手編集しない。
