# AI Agent Shared Rules

.ai/ は Claude Code、Codex など複数の AI エージェントで共有するルールの正本です。

## 必読

- rules/workspace.md
- rules/testing.md
- rules/error-handling.md

## 読み込みモデル

- Claude Code は CLAUDE.md の @import で自動ロードする。
- Codex は AGENTS.md の必読指示から同じルールを読む。
- .claude/ と .codex/ には tool 固有情報を置く。
- docs/specs/ には人間とAIが共有する機能要件を置く。

共通判断の変更は .ai/ の正本だけを更新する。
