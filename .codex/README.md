# Codex Entry

`.codex/` には Codex 固有の接続設定と補足だけを置きます。

## 共通設定

- 入口: `../AGENTS.md`
- rules: `../.ai/rules/**`
- skills: `../.ai/skills/**`（`../.agents/skills` symlink から discovery）
- hooks: `../.ai/hooks/**`

## Codex hooks

`.codex/config.toml` が共通 hook 実装を呼び出します。project を信頼した後、Codex の `/hooks` で内容を確認して有効化してください。共通 hook 本文は `.codex/` に複製しません。
