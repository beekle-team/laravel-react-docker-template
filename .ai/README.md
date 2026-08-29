# AI Agent Shared Configuration

`.ai/` は Claude Code、Codex など複数の AI エージェントで共有する内容の正本です。

## 正本

- `rules/**`: workspace、言語、フレームワーク、テストの規約
- `skills/**`: Agent Skills 形式の共通 workflow と参照資料
- `hooks/**`: lifecycle hook の共通実装と回帰テスト

## 必読

- rules/workspace.md
- rules/testing.md
- rules/error-handling.md

## 接続モデル

- `AGENTS.md` を共通入口とし、Claude Code は `CLAUDE.md` から import する。
- `.claude/rules` は `../.ai/rules` への symlink。
- `.claude/skills` と `.agents/skills` は `../.ai/skills` への symlink。
- Claude Code と Codex の lifecycle 設定だけを、それぞれ `.claude/settings.json` と `.codex/config.toml` に置く。
- `docs/specs/` には人間と AI が共有する機能要件を置く。

共通内容の変更は `.ai/` の正本だけを更新し、symlink 先に複製を作らない。
