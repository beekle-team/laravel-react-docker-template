---
globs: ["src/app/**/*.php","src/bootstrap/**/*.php","src/config/**/*.php","src/database/**/*.php","src/public/index.php","src/routes/**/*.php","src/tests/**/*.php","src/rector.php","src/composer.json","src/composer.lock"]
---

# Rector 自動リファクタ

PHP の構文アップグレードと Laravel 向けリファクタは Rector で行う。フォーマットは Pint、静的解析は Larastan に任せ、Rector は AST 変換だけを担当する。

## トリガー条件

- `app/**/*.php`, `bootstrap/**/*.php`, `config/**/*.php`, `database/**/*.php`, `public/index.php`, `routes/**/*.php`, `tests/**/*.php` を編集・作成した時
- `rector.php` を変更した時
- `composer.json` または `composer.lock` を変更した時。PHP ファイルに差分がなくても、依存更新後の PHP・Laravel バージョンに対応した Rector を実行する

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

## 有効な基盤セット

- PHP 8.5 までの構文変換
- 汎用的な死蔵コード除去
- コード品質改善
- 型宣言追加
- early return
- `instanceof` 改善
- PHPUnit 系コード品質
- Laravel の Composer バージョン連動セット

## Laravel バージョン更新時

`withSetProviders(LaravelSetProvider::class)` と `withComposerBased(laravel: true)` により、インストール済みの `laravel/framework` バージョンに合う移行セットを選ぶ。Laravel の対象バージョンを `rector.php` に手動固定しない。

`composer.json` または `composer.lock` だけを変更したコミットでも、pre-commit hook は Rector の dry-run、Pint、Larastan、Pest を実行する。新しい Laravel バージョン向けの変換が残っていればコミットを止める。

依存更新後は次の順で適用・検証する。

```bash
docker compose exec app composer install
docker compose exec app composer rector:fix
docker compose exec app composer pint
docker compose exec app composer stan
docker compose exec app composer test
```

Rector の dry-run が差分ゼロでも、「利用できるルールがない」とは判断しない。現在のコードが、いま有効なセットに適合しているという意味に限る。

## 方針

- PHP は Composer、Docker、Rector、CI のすべてで 8.5 に統一する
- `withPhpSets(php85: true)` と `PhpVersion::PHP_85` を使い、PHP 8.5 の構文変換を有効にする
- Laravel のバージョン移行ルールは `withComposerBased(laravel: true)` で installed バージョンに合わせる
- 品質セット（`deadCode` / `codeQuality` / `typeDeclarations` / `earlyReturn` / `instanceOf` / `phpunitCodeQuality`）を `withPreparedSets()` で有効にする。バージョン移行セットだけでは死蔵コードと型宣言漏れを拾えない
- Laravel 固有の追加品質ルールは、必要性と差分を確認して `withSets()` に加える
- `AddArrowFunctionReturnTypeRector` は `tests/` で skip する。GWT の `fn () => expect(...)` に Pest 内部型（`\Pest\Mixins\Expectation`）を書かせても読みづらいだけのため
- `LongArrayToShortArrayRector` は Pint と重複するので skip する
- CI は `--dry-run` のみ。自動書き換えはしない
- 新しいセットを足すときは、先に dry-run の差分を見てからにする

## 注意

- Docker 環境: `docker compose exec app ./vendor/bin/rector process --dry-run`
- 設定ファイル: `src/rector.php`
- dry-run が失敗したら、安全な差分は `rector:fix` で適用するか、ノイズになるルールを `withSkip()` する
- Rector 適用後は `composer pint` を再実行する
