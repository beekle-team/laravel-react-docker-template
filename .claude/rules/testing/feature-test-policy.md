# Feature テスト作成ポリシー

## 絶対ルール

**Feature テストは BDD フローを経由してのみ作成可能**

```
❌ 禁止: requirements.md なしで tests/Feature/ にファイル作成
❌ 禁止: Gherkin シナリオなしで Feature テスト実装
❌ 禁止: ユーザー承認なしでテスト生成
✅ 許可: /bdd コマンド経由でのテスト生成
✅ 許可: 既存 requirements.md に基づく追加（承認後）
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
