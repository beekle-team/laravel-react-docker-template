---
paths: ["src/app/Models/**/*.php"]
---

# IDE Helper Auto-Update Rule

モデルファイル編集後は必ず IDE Helper を更新する。

## トリガー条件
- `app/Models/*.php` を編集・作成した時

## 実行コマンド
```bash
php artisan ide-helper:models -W
```

## 注意
- Docker 環境の場合: `docker compose exec app php artisan ide-helper:models -W`
- 複数モデル編集時も最後に1回だけ実行
