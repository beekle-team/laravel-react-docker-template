---
globs: ["src/app/Data/**/*.php","src/app/Enums/**/*.php","src/config/typescript-transformer.php","src/resources/js/types/generated.d.ts"]
---

# TypeScript 型生成ルール

Data クラスや Enum の編集後は TypeScript 型を再生成し、生成物を必ずコミットする。

## トリガー条件
- `app/Data/**/*.php` を編集・作成・削除した時
- `app/Enums/**/*.php` を編集・作成・削除した時
- `config/typescript-transformer.php` を変更した時

## 実行コマンド
```bash
composer types
composer types:check
```

## 注意
- Docker 環境: `docker compose exec app composer types`
- 生成先: `resources/js/types/generated.d.ts`
- 複数 Data / Enum を編集した場合も最後に1回だけ生成する
- CI は生成コマンドを再実行し、差分が出たら失敗する
- 生成ファイルを手編集しない
