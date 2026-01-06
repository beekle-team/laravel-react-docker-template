---
globs: ["src/app/Data/**/*.php"]
---

# TypeScript 型生成ルール

Data クラス編集後は TypeScript 型を再生成する。

## トリガー条件
- `app/Data/*.php` を編集・作成した時

## 実行コマンド
```bash
php artisan typescript:transform
```

## 注意
- Docker 環境: `docker compose exec app php artisan typescript:transform`
- 生成先: `resources/js/types/generated.d.ts`
- 複数 Data クラス編集時も最後に1回だけ実行
