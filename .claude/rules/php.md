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

## 検証コマンド

```bash
# コード品質チェック（CI/プッシュ前に実行）
./vendor/bin/pint --test && ./vendor/bin/phpstan analyse
```
