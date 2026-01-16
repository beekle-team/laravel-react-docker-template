---
name: simplify
description: コードを整理・簡素化。未使用コード削除、ネスト平坦化、重複排除を行う。
license: MIT
---

# Code Simplifier

指定されたファイルまたは直近で編集したファイルのコードを整理・簡素化するスキル。

**Keywords**: simplify, cleanup, refactor, dead-code, unused-imports, early-return

---

## Usage

```
/simplify                    # 直近で編集したファイルを対象
/simplify path/to/file.php   # 指定ファイルを対象
/simplify app/Models/        # ディレクトリ全体を対象
```

---

## Workflow

### Step 1: 対象ファイル特定

- `$ARGUMENTS` があれば、そのファイル/ディレクトリを対象
- なければ、このセッションで編集したファイルを対象

### Step 2: 問題特定

以下の観点でコードを分析:

#### 削除対象
- 未使用の import / use 文
- 未使用の変数・関数
- 冗長なコメント
- デッドコード
- 不要な型アノテーション（自明な場合）

#### 簡素化対象
- 長すぎる関数 → 分割
- 深いネスト → early return で平坦化
- 重複コード → 共通化（過度な抽象化は避ける）
- 不明瞭な命名 → 改善

### Step 3: 最小限の変更で整理

**やらないこと**:
- 機能の追加・変更
- 過度な抽象化
- 不要なデザインパターンの導入

### Step 4: Lint 実行

変更後に lint を実行して確認:

```bash
# PHP
composer lint

# TypeScript
npm run lint && npm run types
```

### Step 5: レポート出力

変更内容を報告:
- 削除したコード量
- 簡素化したロジック
- 改善した命名

---

## Language-Specific Guidelines

### PHP (Laravel)

- `use` 文の整理（Pint で自動フォーマット）
- Eloquent クエリの最適化
- コレクションメソッドの活用
- 型宣言の追加（PHPStan 対応）

```php
// Before
$users = User::all();
$activeUsers = [];
foreach ($users as $user) {
    if ($user->is_active) {
        $activeUsers[] = $user;
    }
}

// After
$activeUsers = User::where('is_active', true)->get();
```

### TypeScript (React)

- 未使用の import 削除
- `any` 型の排除
- カスタムフックへの抽出
- コンポーネントの適切な分割

```tsx
// Before
const handleClick = () => {
    if (isValid) {
        if (hasPermission) {
            if (isReady) {
                doAction();
            }
        }
    }
};

// After
const handleClick = () => {
    if (!isValid) return;
    if (!hasPermission) return;
    if (!isReady) return;
    doAction();
};
```

---

## Output Format

```
## Simplification Report

### Files Modified
- app/Models/User.php
- resources/js/Pages/Dashboard.tsx

### Changes
- Removed 12 unused imports
- Flattened 3 nested conditions using early return
- Extracted 2 reusable functions

### Lint Status
- PHP: ✅ Passed
- TypeScript: ✅ Passed
```
