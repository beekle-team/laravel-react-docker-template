---
paths: ["src/app/**/*.php","src/config/typescript-transformer.php","src/resources/js/types/generated.d.ts"]
---

# TypeScript 型生成ルール

TypeScript Transformer は `app_path()` 全体を探索する。`app/` 配下の PHP、変換設定、または生成物を変更した後は TypeScript 型を再生成し、生成物を必ずコミットする。

## トリガー条件
- `app/**/*.php` を編集・作成・削除した時
- `config/typescript-transformer.php` を変更した時
- `resources/js/types/generated.d.ts` を変更した時

## 実行コマンド
```bash
composer types
composer types:check
```

## 注意
- Docker 環境: `docker compose exec app composer types`
- 生成先: `resources/js/types/generated.d.ts`
- 複数の変換対象を編集した場合も最後に1回だけ生成する
- Data / Enum 以外でも `#[TypeScript]` などのCollector対象は生成型に影響する
- CI は生成コマンドを再実行し、差分が出たら失敗する
- 生成ファイルを手編集しない
