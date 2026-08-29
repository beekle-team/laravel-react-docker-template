# AGENTS.md

このファイルは AI エージェントの共通入口です。共通ルール、skill、hook 本文の正本は `.ai/` に置きます。

## 必読

- .ai/README.md
- .ai/rules/workspace.md
- .ai/rules/testing.md
- .ai/rules/error-handling.md

## 変更対象ごとの詳細ルール

- Laravel / PHP: `.ai/rules/laravel/` と `.ai/rules/php.md`
- React / TypeScript: `.ai/rules/frontend/` と `.ai/rules/type-safety.md`
- Test / static analysis: `.ai/rules/testing/`

## 共通 skill

- 共通 skill の正本は `.ai/skills/**` に置く。
- Claude Code は `.claude/skills`、Codex は `.agents/skills` の symlink から同じ skill を discovery する。

## 品質ゲートとテスト

- 正本は `.ai/rules/workspace.md` の Quality Gates、テスト境界は `.ai/rules/testing.md`、フロント詳細は `.ai/rules/frontend/quality-scans.md` を参照する。
- リポジトリルートで、変更対象に応じて次を実行する。

```bash
bash scripts/check-php-version-consistency.sh
scripts/compose.sh exec app composer lint
scripts/compose.sh up -d --wait postgres-test
scripts/compose.sh exec app composer test
scripts/compose.sh exec app composer types:check # Data DTO・Enum・TypeScript変換対象の変更時
scripts/compose.sh exec app npm run lint:js
scripts/compose.sh exec app npm run types
scripts/compose.sh exec app npm run lint:react-compiler
scripts/compose.sh exec app npm run lint:architecture
scripts/compose.sh exec app npm run test:unit
scripts/compose.sh exec app npm run test:e2e # ユーザーフロー変更時
```

## Codex固有

- Codex固有情報は .codex/ に置く。
- 共通内容は `.ai/` を更新する。
- generated TypeScript と Wayfinder 生成物を手編集しない。
