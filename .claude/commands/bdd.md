# BDD テスト生成

要件定義から GWT パターンの BDD テストを生成する。

## 使い方

```
/bdd {feature-name}
/bdd {feature-name} --spec-only    # requirements.md のみ生成
/bdd {feature-name} --test-only    # テストのみ生成 (既存 spec から)
```

## 実行手順

### 1. 要件定義の確認/作成

`.kiro/specs/$ARGUMENTS/requirements.md` を確認:
- 存在しない場合: ユーザーに要件をヒアリングして作成
- 存在する場合: 内容を読み込む

### 2. requirements.md フォーマット

`.kiro/steering/bdd.md` のフォーマットに従って作成:

```markdown
# {機能名} - 要件定義

## 概要
{機能の説明}

### 設計概要
| 項目               | 内容        |
| ------------------ | ----------- |
| **ユースケース数** | **{N}件**   |
| **シナリオ数**     | **{M}件**   |

## 1. ユースケース一覧
...

## 2. ユースケース詳細

### UC-01: {ユースケース名}
...
**Scenario 1.1: {シナリオ名}**
```gherkin
Given ...
When ...
Then ...
```
```

### 3. GWT テスト生成

requirements.md の各シナリオを `scenario()` ヘルパーを使ったテストに変換:

```php
describe('UC-01: {ユースケース名}', function () {
    it('Scenario 1.1: {シナリオ名}', function () {
        scenario('{シナリオの説明}')
            ->given('{Given の内容}', function () {
                // Gherkin の Given を実装
            })
            ->when('{When の内容}', function ($context) {
                // Gherkin の When を実装
            })
            ->then('{Then の内容}', function ($response) {
                // Gherkin の Then を実装
            })
            ->run();
    });
});
```

### 4. ファイル配置

- Spec: `.kiro/specs/{feature}/requirements.md`
- Test: `src/tests/Feature/{Feature}/{Feature}GwtTest.php`

### 5. テスト実行

```bash
docker compose exec app ./vendor/bin/pest tests/Feature/{Feature}/
```

## 出力例

`/bdd auth` 実行時:

1. `.kiro/specs/auth/spec.json` - メタ情報
2. `.kiro/specs/auth/requirements.md` - 要件定義 (GWT形式)
3. `src/tests/Feature/Auth/AuthGwtTest.php` - BDD テスト

## 参照

- `.kiro/steering/bdd.md` - BDD ガイドライン
- `src/tests/Support/Gwt/Scenario.php` - GWT ヘルパー
- `src/tests/Feature/Gwt/GwtExampleTest.php` - サンプルテスト
