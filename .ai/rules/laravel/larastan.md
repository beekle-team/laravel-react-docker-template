---
paths: ["src/app/**/*.php","src/database/**/*.php","src/routes/**/*.php","src/tests/**/*.php","src/phpstan.neon"]
---

# Larastan 静的解析ルール

PHP ファイル編集後は Larastan (PHPStan) で静的解析を実行する。

## トリガー条件
- `app/**/*.php`, `database/**/*.php`, `routes/**/*.php`, `tests/**/*.php` を編集・作成した時

## 実行コマンド
```bash
./vendor/bin/phpstan analyse
```

## 注意
- Docker 環境: `docker compose exec app ./vendor/bin/phpstan analyse`
- 設定ファイル: `phpstan.neon` (Level 9、対象は `app/` `database/` `routes/` `tests/`)
- Pest のテストクロージャは実行時に TestCase へ束縛されるため、`$this->post()` 等が
  `method.notFound` になる。これだけは `ignoreErrors` で `tests/Feature` に限定して除外している
- カスタムルールは `tests/PHPStan/Rules/**` に置き、`phpstan.neon` の `rules:` に登録する
- エラーが出た場合は修正してから完了とする
