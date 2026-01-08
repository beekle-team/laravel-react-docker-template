# Feature テスト作成ポリシー

## 絶対ルール

**Feature テストは BDD フローを経由してのみ作成可能**

```
禁止: requirements.md なしで tests/Feature/ にファイル作成
禁止: Gherkin シナリオなしで Feature テスト実装
禁止: ユーザー承認なしでテスト生成
禁止: 複数テストを一括で書く（1テストずつ進める）
禁止: テスト失敗のまま次のテストに進む
禁止: scenario() ヘルパーなしで Feature テスト実装 ← 🔴 NEW
許可: /bdd コマンド経由でのテスト生成
許可: 既存 requirements.md に基づく追加（承認後）
必須: 1テストがパスしてから次へ
必須: scenario() ヘルパーを使用した GWT 形式 ← 🔴 NEW
```

## scenario() ヘルパー強制

**🔴 CRITICAL: Feature テストでは必ず `scenario()` ヘルパーを使用**

```php
// ✅ 正しい形式
describe('UC-01: ユーザー登録', function () {
    it('Scenario 1.1: 有効なデータで登録できる', function () {
        scenario('ユーザー登録フロー')
            ->given('有効なユーザーデータ', function () {
                return ['name' => 'Test', 'email' => 'test@example.com'];
            })
            ->when('登録APIを呼び出す', function (array $data) {
                return $this->post('/register', $data);
            })
            ->then('成功する', function ($response) {
                $response->assertRedirect();
            })
            ->run();
    });
});

// ❌ 禁止: scenario() なしの直接テスト
it('registers a user', function () {
    $response = $this->post('/register', [...]);
    expect(...)->toBe(...);
});
```

### 命名規則

| 要素 | 形式 | 例 |
|------|------|-----|
| describe | `UC-XX: {名前}` | `UC-01: ユーザー登録` |
| it | `Scenario X.Y: {名前}` | `Scenario 1.1: 有効なデータで...` |
| ファイル名 | `{Feature}GwtTest.php` | `AuthGwtTest.php` |

### 検出パターン

以下のコードを検出したら即座に修正を要求:

```php
// ❌ これを検出したら違反
it('...', function () {
    $this->post(...);        // scenario() なしの直接リクエスト
    $this->get(...);
    $this->actingAs(...)->post(...);
});
```

## TDD サイクル（1テストずつ）

```
1. テスト1つ書く (Red)
2. テスト実行 → 失敗確認
3. 最小限の実装 (Green)
4. テスト実行 → 成功確認
5. リファクタリング (必要なら)
6. 次のテストへ → 1に戻る
```

## トリガー条件

以下の操作を検出した場合、このルールを適用:

- `tests/Feature/` へのファイル作成・編集
- Feature テスト作成の要求
- 「テスト書いて」「テスト追加して」等の曖昧な指示

## 必須チェック

Feature テスト関連の操作前に必ず確認:

1. **requirements.md の存在確認**
   ```bash
   ls .kiro/specs/{feature}/requirements.md
   ```

2. **Gherkin シナリオの存在確認**
   - requirements.md 内に `Given`, `When`, `Then` が存在するか

3. **ユーザー承認の取得**
   - テスト生成一覧を提示
   - 明示的な承認を得る

## 違反時の対応

requirements.md がない状態でテスト要求された場合:

```
Feature テストを直接作成することはできません。

このプロジェクトでは BDD アプローチを採用しています:

1. まず要件定義が必要です
   → /bdd {feature-name} を実行
   → または、要件をお聞かせください

2. 要件定義後、Gherkin シナリオを作成

3. シナリオに基づいてテストを生成

現在の状態を確認しますか？
```

## Unit テストとの違い

| 種類 | 作成条件 | 承認 |
|------|----------|------|
| Feature テスト | requirements.md + Gherkin 必須 | 必須 |
| Unit テスト | 実装コードがあれば可 | 不要 |

Unit テスト (`tests/Unit/`) はこのルールの対象外。
