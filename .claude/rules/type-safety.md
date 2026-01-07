# Type Safety Rules

## 🔴 CRITICAL ルール（違反禁止）

フロントエンドの型定義は必ず Data クラス経由で自動生成する。

### 絶対禁止事項

- `resources/js/types/index.d.ts` への手動型追加
- `resources/js/types/` 配下への手動 interface/type 追加
- Data クラスなしでのモデル/API レスポンス型定義
- `any` 型の使用

### 違反検出トリガー

以下のパターンを検出した場合、即座に停止して Data クラス作成に切り替える:

- `interface` または `type` を types/ 配下に書こうとした時
- `export interface` を手動で追加しようとした時
- Controller から Inertia にデータを渡す型が必要な時

### 許可される型定義

| 場所 | 許可 | 備考 |
|------|------|------|
| `types/generated.d.ts` | ✅ | 自動生成のみ |
| コンポーネント内 Props | ✅ | ローカルスコープ |
| `types/index.d.ts` | ❌ | 手動追加禁止 |

## 正しいワークフロー

型が必要な場合:

```
1. app/Data/{Model}Data.php を作成
2. Enum が必要なら app/Enums/{Name}.php を作成
3. php artisan typescript:transform を実行
4. generated.d.ts から import して使用
```

## Data クラスの作成例

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]
class UserData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public string $email,
    ) {}
}
```

## 実行コマンド

```bash
# Docker 環境
docker compose exec app php artisan typescript:transform

# ローカル環境
php artisan typescript:transform
```

## 検証方法

型生成後、以下を確認:

1. `resources/js/types/generated.d.ts` に型が追加されている
2. `npx tsc --noEmit` がパスする
3. フロントエンドで型エラーがない
