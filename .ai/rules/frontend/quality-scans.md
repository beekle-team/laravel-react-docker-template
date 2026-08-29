---
paths: ["src/resources/js/**/*.ts","src/resources/js/**/*.tsx","src/package.json","src/knip.json","src/jscpd.json",".github/workflows/*.yml"]
---

# Frontend Quality Scans

フロントエンドの品質ゲートは Biome / TypeScript / React Compiler / knip / jscpd / Vitest を CI で必ず通す。E2E は別ジョブで Playwright を実行する。

## 必須コマンド

```bash
npm run lint:js
npm run types
npm run lint:react-compiler
npm run lint:dead-code
npm run lint:duplication
npm run test:unit
```

## React Compiler

`npm run lint:react-compiler` でビルドと同じコンパイラを走らせ、最適化がスキップされたコンポーネント / フックを検出する。ビルドはスキップしても成功するため、この検査を落とさない。詳細は `.ai/rules/frontend/react-compiler.md` を参照。

## テスト

コンポーネント / hook は Vitest（`npm run test:unit`）、画面をまたぐフローは Playwright（CI の E2E ジョブ）で検証する。配置と書き方は `.ai/rules/frontend/testing.md` を参照。

## Dead Code

`knip` で import されていない export や未使用 dependency を検出する。Wayfinder、生成型、build output は対象外にする。

## Duplication

`jscpd` で手書きコードのコピペを検出する。既存 scaffold の baseline を超えないよう、`jscpd.json` の `threshold` を上限として CI でブロックする。生成物や framework boilerplate は ignore に明示する。

## 例外

- `resources/js/actions/**`
- `resources/js/routes/**`
- `resources/js/wayfinder/**`
- `resources/js/types/generated.d.ts`
- `public/build/**`
