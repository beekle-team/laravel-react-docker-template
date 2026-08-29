# Kiro 廃止と AI 共通ルール移行 設計

## 背景

このリポジトリには、Kiro の spec-driven development 用ファイル、Claude Code の Kiro command、`.kiro/specs/**` を前提とする BDD/TDD 規約が残っている。しかし、現在は Kiro を利用していない。

一方で、Feature test の Gherkin 要件、`scenario()` helper、1シナリオずつの Red → Green → Refactor は、Kiro とは独立した品質ルールとして引き続き有用である。また、プロジェクトでは Claude Code と Codex の双方を利用するため、共通ルールをどちらからも同じ内容で参照できる必要がある。

## 目的

1. Kiro 本体、Kiro command、Kiro 固有参照をリポジトリから完全に削除する。
2. Kiro に依存しない BDD/TDD 規約と既存要件文書を保持する。
3. `.ai/` を Claude Code と Codex が共有するルールの正本にする。
4. `CLAUDE.md` と `AGENTS.md` を tool 固有の薄い入口にする。
5. Issue #23 のエラーハンドリング要件を Kiro 非依存の文書として継続利用する。

## 非目的

- BDD、Gherkin、`scenario()` helper の廃止。
- 既存 Feature test の振る舞いやテストコードの書き換え。
- `.claude/rules/**` にある Laravel / React の詳細ルールを一括移植すること。
- Claude Code 固有 command や skill をすべて Codex 形式へ変換すること。
- エラーハンドリング機能そのものの実装。この変更の完了後に別計画で行う。

## 採用方式

zutool-flutter-v1 と同じく、tool 非依存の共通ルールを `.ai/` に置き、各 AI エージェントの入口から参照する。

```text
.ai/                              共通ルールの正本
├── README.md                     配置方針と読み込みモデル
└── rules/
    ├── workspace.md              プロジェクト共通ルール
    ├── testing.md                BDD/TDDとテスト境界
    └── error-handling.md         Issue #23 の異常系ルール

CLAUDE.md                         Claude Code の薄い入口
AGENTS.md                         Codex の薄い入口
.claude/                          Claude Code 固有機能とnative rules
.codex/                           Codex 固有情報
docs/specs/                       人間とAIが共有する要件文書
```

### 読み込みモデル

- Claude Code は `CLAUDE.md` の `@import` で必須の `.ai/rules/**` を起動時に読み込む。
- Codex は `AGENTS.md` の必読指示に従って同じ `.ai/rules/**` を読む。
- `.claude/rules/**` は Claude Code の native auto-load を維持する。Codex は `AGENTS.md` から、変更対象に対応する詳細ルールを必要時に読む。
- 共通判断を追加・変更する場合は `.ai/` を更新する。tool 固有入口へ同じ本文を複製しない。

## 削除対象

### `.kiro/`

次を含む `.kiro/` 全体を削除する。

- `.kiro/settings/rules/**`
- `.kiro/settings/templates/**`
- `.kiro/steering/**`
- `.kiro/specs/**`

要件文書は削除前に `docs/specs/**` へ移動する。

### Claude Code の Kiro command

`.claude/commands/kiro/` を全削除する。次の command 群は代替を作らない。

- steering / steering-custom
- spec-init / spec-requirements / spec-design / spec-tasks / spec-impl
- spec-status
- validate-gap / validate-design / validate-impl

設計と実装計画は、Claude Code / Codex 共通の通常ワークフローと `docs/specs/**` を使う。

## 文書移行

| 移行元 | 移行先 | 方針 |
| --- | --- | --- |
| `.kiro/specs/auth/requirements.md` | `docs/specs/auth/requirements.md` | 内容を保持し、参照パスだけ変更 |
| `.kiro/specs/error-handling/requirements.md` | `docs/specs/error-handling/requirements.md` | Issue #23 の要件として保持し、Kiro固有記述を除去 |
| `.kiro/steering/bdd.md` | `.ai/rules/testing.md` | 重複を整理して共通テスト規約へ統合 |
| `.kiro/specs/*/spec.json` | 移行しない | Kiro のphase statusなので削除 |

`docs/specs/**` は製品・機能要件の保存場所であり、AI tool の状態管理には使わない。

## BDD/TDD 規約

Kiro を削除しても、次の規約は維持する。

- Feature test の前に `docs/specs/{feature}/requirements.md` へ Gherkin scenario を記載する。
- Feature test は `scenario()` helper を使う。
- 1シナリオずつ Red → Green → Refactor する。
- 現在のテストが通るまで次のシナリオへ進まない。
- Vitest、Playwright、Arch test、PHPStan rule は、それぞれ既存のテスト境界に従う。

次のファイルを新しい参照先へ更新する。

- `.claude/commands/bdd.md`
- `.claude/skills/tdd-methodology/SKILL.md`
- `.claude/rules/testing/feature-test-policy.md`
- `.claude/rules/testing/architecture-tests.md`
- `.claude/rules/frontend/testing.md`
- `src/tests/Feature/Gwt/GwtExampleTest.php`
- `src/tests/Feature/Auth/AuthGwtTest.php`

Kiro command 実行を必須とする記述は削除し、要件文書、承認、Gherkin、TDD cycle という tool 非依存の条件に置き換える。

## AI 共通ルール

### `.ai/README.md`

次を記載する。

- `.ai/` が共通ルールの正本であること。
- Claude Code と Codex の読み込み方法。
- `.claude/` と `.codex/` には tool 固有情報を置くこと。
- `docs/specs/**` が機能要件の保存場所であること。

### `.ai/rules/workspace.md`

現在の `CLAUDE.md` にある Kiro 非依存のプロジェクト共通ルールを移す。

- 日本語で応答すること。
- Form Request / Precognition。
- Inertia props と Data DTO。
- Model layer boundaries。
- React feature architecture と React Compiler。
- PHP / frontend quality gate。
- テスト種別の境界。

詳細本文は既存 `.claude/rules/**` を正としてリンクし、同じ詳細を複製しない。

### `.ai/rules/testing.md`

BDD/TDD の tool 非依存規約、`docs/specs/**` の配置、`scenario()` helper、テスト種別の境界を定義する。

### `.ai/rules/error-handling.md`

Issue #23 で合意した次の分類表をそのまま残す。

| 分類 | 既定の表示 | 復旧方法 |
| --- | --- | --- |
| 入力・422 | インライン | 該当フィールドを修正 |
| ドメインエラー | トースト | 内容を修正して再実行 |
| ネットワークエラー | 操作箇所内またはトースト | 安全な場合のみ再試行 |
| 認証・401/419 | モーダルまたはflash | ログイン・再送信 |
| 操作権限・403 | モーダル | 戻る・一覧へ移動 |
| ページ権限・403 | エラーページ | ホームへ戻る |
| 操作対象なし・404 | モーダルまたはトースト | 再読込・一覧へ移動 |
| ページなし・404 | エラーページ | ホーム・任意の検索 |
| 復旧可能なシステムエラー | トースト | 再試行 |
| 復旧不能な500/503 | エラーページ | 再読込・ホーム・問い合わせ |

このファイルには、表示分類に加えて情報漏洩防止、復旧 action、semantic token、アクセシビリティ、Inertia と個別 JSON 通信の境界を記載する。

## Agent 入口

### `CLAUDE.md`

- `.ai/rules/workspace.md`、`.ai/rules/testing.md`、`.ai/rules/error-handling.md` を `@import` する。
- Claude Code 固有 command / skill / native rule の案内だけを残す。
- Kiro の説明、phase、command、`.kiro/` 参照を削除する。

### `AGENTS.md`

- Codex の入口として新規作成する。
- `.ai/README.md` と必須の `.ai/rules/**` を必読にする。
- 変更対象に対応する `.claude/rules/**` も必要時に読むよう指示する。
- generated files、品質 gate、テスト command の最小案内を置く。

### `.codex/README.md`

- Codex 固有情報の置き場所であることを説明する。
- 共通ルールは `.ai/` を参照するよう案内する。

## `.dockerignore`

存在しなくなる `.kiro` entry を削除する。`.ai/` と `docs/specs/` はリポジトリの開発用文書として保持する。Docker build context から除外するかどうかは runtime image の要件と独立して扱い、この変更では新たな ignore を追加しない。

## 安全性

- `.kiro/` 削除前に、人間が読む価値のある要件文書と BDD 規約を移動する。
- `.kiro/settings/**` と `spec.json` は Kiro 固有メタデータなので移行しない。
- ユーザー所有の他の変更へ触れない。
- 削除後に参照切れを全件検索する。

## 検証

実装後に次を確認する。

1. `find .kiro` が対象なしになる。
2. `.claude/commands/kiro/` が存在しない。
3. `.git`、依存物、この移行を記録する `docs/superpowers/**` を除く `rg -i '\.kiro|kiro:'` が0件になる。
4. `docs/specs/auth/requirements.md` と `docs/specs/error-handling/requirements.md` が存在する。
5. GWT test の `@see` が新しい要件文書を指す。
6. `CLAUDE.md` と `AGENTS.md` の双方から同じ `.ai/rules/**` へ到達できる。
7. `git diff --check` が成功する。
8. 文書・コメント・AI設定だけの変更であることを確認し、アプリケーションの実行時コードに差分がないことを確認する。

## 実装順序

1. `docs/specs/**` と `.ai/rules/**` を作成して、保持対象を先に退避する。
2. `CLAUDE.md`、`AGENTS.md`、`.codex/README.md` を共通ルールへ接続する。
3. BDD command、skill、testing rule、test comment の参照を更新する。
4. `.claude/commands/kiro/` と `.kiro/` を削除する。
5. `.dockerignore` を更新する。
6. 残存参照と差分を検証する。
