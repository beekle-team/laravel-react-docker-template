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

## 設定 (Biome 2)

- import の並び替えは linter ではなく assist の担当。`assist.actions.source.organizeImports` で有効化する
- 対象ファイルは `files.includes` に glob で書く。除外は `!` 付きの否定 glob
- 生成物・ロックファイル・テスト成果物（`public/build`、`package-lock.json`、`test-results`、`playwright-report` など）は必ず否定 glob で除外する。Biome 2 は JSON や HTML も検査対象にするため、除外し忘れると大量の指摘が出る
- Tailwind の at-rule は `suspicious.noUnknownAtRules` の `ignore` に列挙する。ルール自体は有効に保つ
- メジャー更新時は `npx biome migrate --write` で設定を移行する
