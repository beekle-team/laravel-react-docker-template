# Smart Commit

変更内容を分析して適切なコミットを作成します。

## 手順

1. `git status` と `git diff` で変更内容を確認
2. **品質ゲート (MANDATORY)**: Lintを実行して全てパスすること
   ```bash
   # PHP (Pint + PHPStan + Rector) - srcディレクトリ内で実行
   cd src && composer lint

   # TypeScript/React (Biome)
   cd src && npm run lint:js

   # Docker環境の場合
   docker compose exec app composer pint
   docker compose exec app composer stan
   docker compose exec app npm run lint:js
   ```
   - **Lint失敗時は絶対にコミットしない**
   - 修正: `docker compose exec app composer pint` または `docker compose exec app npm run check`
3. 変更の目的を分析（新機能、バグ修正、リファクタ等）
4. Conventional Commits形式でメッセージを作成
5. コミットを実行

## 重要: Lint必須ルール

**コミット前に必ずLintを実行し、全てパスすることを確認すること。**

このルールは `.claude/settings.local.json` の `PreToolUse` hookで自動強制されます。
`git commit` 実行時に自動的にlintが走り、失敗するとコミットがブロックされます。

## コミットメッセージ形式

```
<type>(<scope>): <description>

<body>
```

### type
- `feat`: 新機能
- `fix`: バグ修正
- `refactor`: リファクタリング
- `docs`: ドキュメント
- `test`: テスト
- `chore`: その他
- `style`: フォーマット変更

### scope
- `backend`: Laravel / PHP 関連
- `frontend`: React / TypeScript 関連
- `api`: API エンドポイント関連
- `db`: データベース・マイグレーション関連
- `auth`: 認証・認可関連
- `ui`: UIコンポーネント関連

### 例

```
feat(api): ユーザープロフィールAPIを追加

- UserController に show/update アクションを追加
- UserData DTO でレスポンス型を定義
- FormRequest でバリデーション実装
```

## 重要

- **Lintが通るまでコミットしない**（最重要）
- secretsファイル（.env等）は絶対にコミットしない
- 新機能にはテストが含まれているか確認
- 大きな変更は複数のコミットに分割を検討
