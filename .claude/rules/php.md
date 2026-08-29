# PHP Coding Rules

## 実行バージョン

PHP はローカル、Docker、Composer、Rector、CI のすべてで **8.5** に統一する。
下位バージョン互換のために PHP 8.5 の構文や標準機能を避けない。

## Strict Types

全PHPファイルに `declare(strict_types=1);` を必須とする。

```php
<?php

declare(strict_types=1);

namespace App\...;
```

**設定**: `pint.json` → `"declare_strict_types": true`

## コードスタイル

Laravel Pint (PSR-12ベース) に準拠。

```bash
./vendor/bin/pint        # フォーマット実行
./vendor/bin/pint --test # チェックのみ
```

**設定**: `pint.json` → `"preset": "laravel"`

## 静的解析

PHPStan Level 9 + Larastan。解析対象は `app/` だけでなく `database/` `routes/` `tests/` も含む。

```bash
./vendor/bin/phpstan analyse
```

**設定**: `phpstan.neon` → `level: 9`

プロジェクト固有の設計ルールのうち、AST を見ないと判定できないものはカスタムルールとして
`tests/PHPStan/Rules/**` に置き、`phpstan.neon` の `rules:` に登録する。
Pest arch テストで表現できるもの（クラスの有無・継承・依存）は arch テスト側に置く。
使い分けは `.claude/rules/testing/architecture-tests.md` を参照。

## 自動リファクタ

Rector（PHP 8.5 + Laravel composer-based）。フォーマットは Pint に任せる。

```bash
./vendor/bin/rector process --dry-run  # 変更確認（CI と同じ）
./vendor/bin/rector process            # 適用
```

**設定**: `rector.php` → `withPhpSets(php85: true)` / `PhpVersion::PHP_85` /
`withPreparedSets(deadCode, codeQuality, typeDeclarations, earlyReturn, instanceOf, phpunitCodeQuality)`

## 型宣言

- 引数の型宣言: 必須
- 戻り値の型宣言: 必須
- プロパティの型宣言: 推奨

```php
// Good
public function findUser(int $id): ?User
{
    return User::find($id);
}

// Bad
public function findUser($id)
{
    return User::find($id);
}
```

## IDE Helper 自動更新

モデルファイル (`app/Models/*.php`) を編集した後、IDE Helper を更新する。

**トリガー**: `app/Models/` 配下の PHP ファイルを編集・作成した時

**実行コマンド**:
```bash
php artisan ide-helper:models -W  # モデルの DocBlock を更新
```

**対象**:
- モデルのプロパティ追加・変更
- リレーション追加・変更
- スコープ追加・変更
- アクセサ/ミューテタ追加・変更

## 検証コマンド

```bash
# コード品質チェック（CI/プッシュ前に実行）
composer lint
```
