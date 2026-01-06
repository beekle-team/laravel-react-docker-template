---
globs: ["src/app/**/*.php","src/tests/**/*.php"]
---

# Larastan 静的解析ルール

PHP ファイル編集後は Larastan (PHPStan) で静的解析を実行する。

## トリガー条件
- `app/**/*.php`, `tests/**/*.php` を編集・作成した時

## 実行コマンド
```bash
./vendor/bin/phpstan analyse
```

## 注意
- Docker 環境: `docker compose exec app ./vendor/bin/phpstan analyse`
- 設定ファイル: `phpstan.neon` (Level 5)
- エラーが出た場合は修正してから完了とする
