# CLAUDE.md
このファイルは Claude Code の入口です。AIエージェント共通ルールの正本は .ai/ に置きます。
## 共通ルール（自動ロード）
@.ai/rules/workspace.md
@.ai/rules/testing.md
@.ai/rules/error-handling.md
## 必要時に参照
- .ai/README.md — 配置方針と読み込みモデル
- docs/specs/ — 機能要件とGherkin scenario
- .claude/rules/ — Laravel、React、テストの詳細ルール
- .claude/commands/ — Claude Code固有command
- .claude/skills/ — Claude Code固有skill
共通ルール変更時は原則 .ai/ を更新する。
