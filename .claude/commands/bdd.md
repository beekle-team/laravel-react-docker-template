# BDD テスト生成

要件定義から GWT パターンの BDD テストを生成する。

## 使い方

```
/bdd {feature-name}
/bdd {feature-name} --spec-only    # requirements.md のみ生成
/bdd {feature-name} --test-only    # テストのみ生成 (既存 spec から)
```

---

## 重要: Feature テスト生成ルール

### 絶対禁止事項

1. **requirements.md なしでの Feature テスト作成は禁止**
   - `.kiro/specs/{feature}/requirements.md` が存在しない状態で Feature テストを書いてはならない
   - 「とりあえずテスト書く」は BDD 違反

2. **Gherkin シナリオなしでの実装は禁止**
   - requirements.md に Gherkin 形式のシナリオが記述されていない場合、テストを書いてはならない
   - シナリオがなければ、まずユーザーにヒアリングして requirements.md を作成する

3. **勝手な Feature テスト追加は禁止**
   - `/bdd` コマンド経由以外での Feature テスト作成は原則禁止
   - 例外: 既存の requirements.md に基づく追加シナリオのみ

### 必須フロー

```
[ユーザー要求]
     ↓
[requirements.md 存在確認] ── なし ──→ [ヒアリング] → [requirements.md 作成] → [ユーザー承認待ち]
     ↓ あり                                                ↓
[Gherkin シナリオ確認] ── なし ──→ [シナリオ追加] → [ユーザー承認待ち]
     ↓ あり
[GWT テスト生成]
     ↓
[テスト実行・確認]
```

### 承認ポイント

以下の段階でユーザー承認を必須とする：

1. **requirements.md 新規作成時**: 内容をユーザーに提示し、承認を得る
2. **シナリオ追加時**: 追加シナリオをユーザーに提示し、承認を得る
3. **テスト生成前**: 生成するテストの一覧を提示し、承認を得る

---

## 実行手順

### 1. 要件定義の確認/作成

`.kiro/specs/$ARGUMENTS/requirements.md` を確認:

**存在しない場合**:
1. ユーザーに以下をヒアリング:
   - 機能の目的・概要
   - 主要なユースケース
   - 各ユースケースの具体的なシナリオ
2. ヒアリング結果から requirements.md を作成
3. **ユーザーに内容を提示し、承認を得る**
4. 承認後、ファイルを保存

**存在する場合**:
1. 内容を読み込む
2. Gherkin シナリオが存在するか確認
3. シナリオがなければユーザーにヒアリングして追加

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

### 3. テスト生成前の確認

**テスト生成前に必ず以下を提示**:

```
生成予定のテスト:
- tests/Feature/{Feature}/{Feature}GwtTest.php
  - UC-01: {ユースケース名}
    - Scenario 1.1: {シナリオ名}
    - Scenario 1.2: {シナリオ名}
  - UC-02: {ユースケース名}
    - Scenario 2.1: {シナリオ名}

上記のテストを生成してよろしいですか？
```

ユーザーの承認後にのみテストを生成する。

### 4. GWT テスト生成

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

### 5. ファイル配置

- Spec: `.kiro/specs/{feature}/requirements.md`
- Test: `tests/Feature/{Feature}/{Feature}GwtTest.php`

### 6. テスト実行

```bash
docker compose exec app ./vendor/bin/pest tests/Feature/{Feature}/
```

---

## エラー処理

### requirements.md がない状態で Feature テスト要求された場合

```
❌ Feature テストを直接作成することはできません。

BDD アプローチでは、まず要件定義が必要です:
1. /bdd {feature-name} を実行してください
2. または、要件を教えていただければ requirements.md を作成します

現在の状態:
- .kiro/specs/{feature}/requirements.md: 存在しません
```

### Gherkin シナリオがない場合

```
❌ テスト生成にはシナリオ定義が必要です。

requirements.md にシナリオが定義されていません。
以下の情報を教えてください:
- このユースケースで想定される操作は？
- 成功時の期待結果は？
- エラーケースは？
```

---

## 出力例

`/bdd auth` 実行時:

1. `.kiro/specs/auth/spec.json` - メタ情報
2. `.kiro/specs/auth/requirements.md` - 要件定義 (GWT形式)
3. `tests/Feature/Auth/AuthGwtTest.php` - BDD テスト

---

## 参照

- `.kiro/steering/bdd.md` - BDD ガイドライン
- `tests/Support/Gwt/Scenario.php` - GWT ヘルパー
- `tests/Feature/Gwt/GwtExampleTest.php` - サンプルテスト
