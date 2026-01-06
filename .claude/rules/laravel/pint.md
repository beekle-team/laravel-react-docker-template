---
globs: ["src/app/**/*.php","src/tests/**/*.php"]
---

# Pint 自動フォーマット

PHP ファイル編集後は Pint でフォーマットする。

## トリガー条件
- `app/**/*.php`, `tests/**/*.php` を編集・作成した時

## 実行コマンド
```bash
./vendor/bin/pint {編集したファイル}
```

## 注意
- Docker 環境: `docker compose exec app ./vendor/bin/pint {file}`
- 複数ファイル編集時は最後にまとめて実行可
- `--test` オプションでチェックのみも可能
