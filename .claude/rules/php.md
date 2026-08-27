# PHP Coding Rules

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

PHPStan Level 5 + Larastan。

```bash
./vendor/bin/phpstan analyse
```

**設定**: `phpstan.neon` → `level: 5`

## 自動リファクタ

Rector（PHP 8.3 + Laravel composer-based）。フォーマットは Pint に任せる。

```bash
./vendor/bin/rector process --dry-run  # 変更確認（CI と同じ）
./vendor/bin/rector process            # 適用
```

**設定**: `rector.php` → `withPhpSets(php83: true)` / `PhpVersion::PHP_83`

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
./vendor/bin/pint --test && ./vendor/bin/phpstan analyse && ./vendor/bin/rector process --dry-run
```
