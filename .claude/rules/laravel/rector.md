---
globs: ["src/app/**/*.php","src/bootstrap/app.php","src/config/**/*.php","src/database/**/*.php","src/routes/**/*.php","src/tests/**/*.php","src/rector.php"]
---

# Rector 自動リファクタ

PHP の構文アップグレードと Laravel 向けリファクタは Rector で行う。フォーマットは Pint、静的解析は Larastan に任せ、Rector は AST 変換だけを担当する。

## トリガー条件

- `app/**/*.php`, `bootstrap/app.php`, `config/**/*.php`, `database/**/*.php`, `routes/**/*.php`, `tests/**/*.php` を編集・作成した時
- `rector.php` を変更した時

## 実行コマンド

```bash
# 変更確認（CI と同じ。コードは書き換えない）
./vendor/bin/rector process --dry-run

# 適用
./vendor/bin/rector process
```

Composer スクリプト:

```bash
composer rector      # dry-run
composer rector:fix  # 適用
```

## 方針

- `phpVersion` は PHP 8.3（composer / Laravel 13 の下限）。`withPhpSets(php83: true)` も 8.3 まで。Docker / CI 本命の 8.5 専用構文は入れない
- Laravel ルールは `withComposerBased(laravel: true)` で installed バージョンに合わせる
- 品質セット（`deadCode` / `codeQuality` / `typeDeclarations` / `earlyReturn` / `instanceOf` /
  `phpunitCodeQuality`）を有効にする。バージョン移行セットだけでは死蔵コードと型宣言漏れを拾えない
- `AddArrowFunctionReturnTypeRector` は `tests/` で skip する。GWT の `fn () => expect(...)` に
  Pest 内部型（`\Pest\Mixins\Expectation`）を書かせても読みづらいだけのため
- `LongArrayToShortArrayRector` は Pint と重複するので skip する
- CI は `--dry-run` のみ。自動書き換えはしない
- さらにセットを足すときは、先に dry-run の差分を見てからにする

## 注意

- Docker 環境: `docker compose exec app ./vendor/bin/rector process --dry-run`
- 設定ファイル: `src/rector.php`
- dry-run が失敗したら、安全な差分は `rector:fix` で適用するか、ノイズになるルールを `withSkip()` する
- Pint の後に Rector を走らせるとフォーマットが崩れることがある。適用後は `composer pint` を再実行する
