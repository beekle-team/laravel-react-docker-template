---
name: smart-commit
description: 品質ゲート付きスマートコミット。Lint通過後に適切なコミットを作成。
license: MIT
---

# Smart Commit - 品質ゲート付きスマートコミット

変更内容を分析して適切なコミットを作成するスキル。Lint通過を必須条件とし、Conventional Commits形式でメッセージを生成。

**Keywords**: commit, git, lint, conventional-commits, quality-gate, pint, phpstan, biome

## コミットフロー

### 1. 変更内容の確認

```bash
git status
git diff
```

### 2. 品質ゲート（MANDATORY）

**Lintを実行して全てパスすることを確認**

```bash
# PHP (Pint + PHPStan)
cd src && composer pint
cd src && composer stan

# TypeScript/React (Biome)
cd src && npm run lint:js

# Docker環境の場合
docker compose exec app composer pint
docker compose exec app composer stan
docker compose exec app npm run lint:js
```

**重要ルール**:
- Lint失敗時は絶対にコミットしない
- 修正コマンド: `cd src && composer pint -- --fix` または `cd src && npm run lint:js:fix`

### 3. 変更分析

変更の目的を分析:
- 新機能（feat）
- バグ修正（fix）
- リファクタリング（refactor）
- ドキュメント（docs）
- テスト（test）
- その他（chore）
- フォーマット変更（style）

### 4. コミットメッセージ作成

Conventional Commits形式でメッセージを作成

### 5. コミット実行

## コミットメッセージ形式

```
<type>(<scope>): <description>

<body>
```

### type

| Type | 説明 |
|------|------|
| `feat` | 新機能 |
| `fix` | バグ修正 |
| `refactor` | リファクタリング |
| `docs` | ドキュメント |
| `test` | テスト |
| `chore` | その他 |
| `style` | フォーマット変更 |

### scope

| Scope | 説明 |
|-------|------|
| `backend` | Laravel / PHP 関連 |
| `frontend` | React / TypeScript 関連 |
| `api` | API エンドポイント関連 |
| `db` | データベース・マイグレーション関連 |
| `auth` | 認証・認可関連 |
| `ui` | UIコンポーネント関連 |

### コミットメッセージ例

```
feat(api): ユーザープロフィールAPIを追加

- UserController に show/update アクションを追加
- UserData DTO でレスポンス型を定義
- FormRequest でバリデーション実装
```

## 品質ゲートの自動実行

このルールは `.claude/settings.local.json` の `PreToolUse` hookで自動強制されます。
`git commit` 実行時に自動的にlintが走り、失敗するとコミットがブロックされます。

## チェックリスト

コミット前に確認:

- [ ] Lint（Pint + PHPStan + Biome）が全てパスしている
- [ ] secretsファイル（.env等）が含まれていない
- [ ] 新機能にはテストが含まれている
- [ ] 大きな変更は複数のコミットに分割検討済み

## コマンド一覧

### Lint実行

```bash
# PHP
cd src && composer pint && composer stan

# TypeScript/React
cd src && npm run lint:js

# 全て実行
cd src && composer pint && composer stan && npm run lint:js
```

### 自動修正

```bash
# PHP
cd src && composer pint -- --fix

# TypeScript/React
cd src && npm run lint:js:fix
```

### Docker環境

```bash
# PHP
docker compose exec app composer pint
docker compose exec app composer stan

# TypeScript/React
docker compose exec app npm run lint:js
```

## アンチパターン

### 避けるべきコミット

```bash
# ❌ BAD: Lint失敗を無視
git commit -m "fix: とりあえずコミット"  # Lint未実行

# ❌ BAD: 曖昧なメッセージ
git commit -m "update"
git commit -m "fix bug"
git commit -m "changes"

# ❌ BAD: secretsを含む
git add .env
git commit -m "feat: 設定追加"
```

### 正しいコミット

```bash
# ✅ GOOD: Lint通過後に具体的なメッセージ
cd src && composer pint && composer stan && npm run lint:js
git add app/Http/Controllers/UserController.php
git commit -m "feat(api): ユーザープロフィール取得APIを追加"
```

## 統合

このスキルは以下と連携:

- `/review` - コードレビュー後にコミット
- `/verify` - 検証完了後にコミット
- TDD Methodology - テスト追加後にコミット
