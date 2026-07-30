---
globs: ["src/resources/js/**/*.ts","src/resources/js/**/*.tsx","src/package.json","src/knip.json","src/jscpd.json",".github/workflows/*.yml"]
---

# Frontend Quality Scans

フロントエンドの品質ゲートは Biome / TypeScript / knip / jscpd を CI で必ず通す。

## 必須コマンド

```bash
npm run lint:js
npm run types
npm run lint:dead-code
npm run lint:duplication
```

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
