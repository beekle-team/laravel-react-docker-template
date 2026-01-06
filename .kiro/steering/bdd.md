# BDD (Behavior-Driven Development) ガイドライン

## 概要

本プロジェクトでは BDD アプローチを採用し、要件定義から実装・テストまで一貫した形式で記述する。

## 開発フロー

```
1. 要件定義 (.kiro/specs/{feature}/requirements.md)
   ↓ Gherkin形式でシナリオを記述
2. BDDテスト作成 (tests/Feature/{Feature}/*GwtTest.php)
   ↓ scenario() ヘルパーで GWT パターン実装
3. 実装
   ↓ テストが通るように実装
4. リファクタリング
```

## requirements.md フォーマット

```markdown
# {機能名} - 要件定義

## 概要
{機能の説明}

### 設計概要
| 項目               | 内容        |
| ------------------ | ----------- |
| **ユースケース数** | **{N}件**   |
| **シナリオ数**     | **{M}件**   |

---

## 1. ユースケース一覧

### 1.1 全体マップ
```
[{機能名}]
├─ UC-01: {ユースケース名}
├─ UC-02: {ユースケース名}
└─ UC-03: {ユースケース名}
```

### 1.2 優先度と概要
| ID    | ユースケース名 | 優先度 | シナリオ数 |
| ----- | ------------- | ------ | ---------- |
| UC-01 | ...           | 最高   | N          |

---

## 2. ユースケース詳細

### UC-01: {ユースケース名}

#### 概要
{ユースケースの説明}

#### アクター
- {誰が実行するか}

#### ビジネス価値
{なぜこの機能が必要か}

#### 前提条件
- {前提条件1}
- {前提条件2}

#### 基本フロー

**Scenario 1.1: {シナリオ名}**

```gherkin
Given {前提条件}
And {追加の前提条件}
When {アクション}
Then {期待結果}
And {追加の検証}
```

#### 受け入れ基準
- [ ] {基準1}
- [ ] {基準2}

#### 影響範囲
- `App\...`
```

## GWT テストフォーマット

```php
<?php

declare(strict_types=1);

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

/**
 * {機能名} - GWT テスト
 *
 * @see .kiro/specs/{feature}/requirements.md
 */

describe('UC-01: {ユースケース名}', function () {
    it('Scenario 1.1: {シナリオ名}', function () {
        scenario('{シナリオの説明}')
            ->given('{前提条件}', function () {
                // セットアップ処理
                return $data;
            })
            ->and('{追加の前提条件}', function ($previousData) {
                // 追加のセットアップ
                return $moreData;
            })
            ->when('{アクション}', function ($context) {
                // テスト対象の実行
                return $this->post('/api/...', $context);
            })
            ->then('{期待結果}', function ($response) {
                // アサーション
                $response->assertOk();
            })
            ->and('{追加の検証}', function ($response) {
                expect(...)->toBe(...);
            })
            ->run();
    });
});
```

## scenario() ヘルパー

`tests/Support/Gwt/Scenario.php` で定義されたビルダークラス。

### メソッドチェーン

| メソッド | 説明 | 戻り値 |
|---------|------|--------|
| `given(string, Closure)` | 前提条件を設定 | Scenario |
| `and(string, Closure)` | 追加の条件/検証 | Scenario |
| `when(string, Closure)` | アクションを実行 | Scenario |
| `then(string, Closure)` | 結果を検証 | Scenario |
| `run()` | シナリオを実行 | void |

### コンテキストの受け渡し

```php
->given('データA', fn () => $a)           // $a を返す
->and('データB', fn ($a) => ['a' => $a, 'b' => $b])  // 前の結果を受け取る
->when('実行', fn ($ctx) => doSomething($ctx))       // 累積されたコンテキスト
->then('検証', fn ($result) => ...)                  // when の結果
```

## ファイル配置

```
.kiro/specs/
└── {feature}/
    ├── spec.json           # メタ情報
    └── requirements.md     # 要件定義 (GWT形式)

src/tests/
├── Feature/
│   └── {Feature}/
│       └── {Feature}GwtTest.php  # Feature レベル BDD テスト
├── Unit/
│   └── {Feature}/
│       └── {Feature}Test.php     # Unit レベルテスト
└── Support/
    └── Gwt/
        └── Scenario.php          # GWT ヘルパー
```

## 命名規則

| 対象 | 規則 | 例 |
|------|------|-----|
| Spec ディレクトリ | kebab-case | `auth`, `user-profile` |
| テストファイル | PascalCase + GwtTest | `AuthGwtTest.php` |
| describe | UC番号 + 名前 | `UC-01: ユーザー登録` |
| it | Scenario番号 + 名前 | `Scenario 1.1: 有効なデータで...` |

## コマンド

```bash
# BDD テスト生成
/bdd {feature-name}

# テスト実行
docker compose exec app ./vendor/bin/pest tests/Feature/{Feature}/
```
