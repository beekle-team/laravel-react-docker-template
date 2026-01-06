---
globs: ["src/resources/js/**/*.tsx","src/resources/js/**/*.ts"]
---

# Biome 自動フォーマット

TypeScript/React ファイル編集後は Biome でフォーマットする。

## トリガー条件
- `resources/js/**/*.tsx`, `resources/js/**/*.ts` を編集・作成した時

## 実行コマンド
```bash
npx biome format --write {編集したファイル}
```

## 注意
- lint も同時に実行する場合: `npx biome check --write {file}`
- 複数ファイル編集時は最後にまとめて実行可
