# AI エージェント設定全面共通化 設計

## 背景

このリポジトリは `.ai/` を Claude Code と Codex の共通ルールの正本と定義しているが、Laravel、PHP、React、TypeScript、テストの詳細ルールが `.claude/rules/**` に残っている。`AGENTS.md` も Codex に `.claude/rules/**` を読むよう案内しており、宣言と配置が一致していない。

同じ問題は rules 以外にもある。再利用可能な skill、BDD や検証などの workflow、品質ガードの実装が `.claude/**` にだけ置かれているため、Codex では自動検出または自動実行されない。

## 目的

- AI エージェント共通の判断、workflow、品質ガードを単一の正本へ集約する。
- Claude Code と Codex が、それぞれの native discovery を使って同じ正本を読む。
- `.claude/` と `.codex/` には tool 固有の設定と接続情報だけを残す。
- 共通設定が再び tool 固有ディレクトリへ混入した場合に CI で検出する。

## 正本と配置

共通正本は `.ai/` に置く。

```text
.ai/
├── README.md
├── rules/
│   ├── workspace.md
│   ├── testing.md
│   ├── error-handling.md
│   ├── php.md
│   ├── type-safety.md
│   ├── frontend/
│   ├── laravel/
│   └── testing/
├── skills/
│   ├── backend-guidelines/
│   ├── brand-guidelines/
│   ├── dry-check/
│   ├── frontend-design/
│   ├── inertia-react/
│   ├── tdd-methodology/
│   ├── bdd/
│   ├── commit/
│   ├── review/
│   ├── simplify/
│   └── verify/
├── hooks/
│   ├── tests/
│   └── *.sh
└── tests/
    └── agent-config-layout-test.sh
```

tool native の探索場所は symlink で正本へ接続する。

```text
.claude/rules  -> ../.ai/rules
.claude/skills -> ../.ai/skills
.agents/skills -> ../.ai/skills
```

Claude Code は `.claude/rules` と `.claude/skills` を、Codex は `.agents/skills` を native discovery で検出する。Claude Code の rules symlink と Codex の skill symlink は、それぞれの公式仕様でサポートされる。

## 共通内容の分類

### Rules

常時守る設計判断とコーディング規約を `.ai/rules/**` に置く。

- Laravel / PHP の設計、型、format、静的解析、生成型
- React / TypeScript の配置、compiler、format、型安全性
- BDD、テスト境界、architecture test
- 品質ゲート
- error handling

変更対象が限定される rule は `paths` frontmatter で対象を宣言する。これは Claude Code の遅延ロードに使うと同時に、他エージェントにとっても適用範囲を示すメタデータとして扱う。旧 `globs` frontmatter は使用しない。

### Skills

依頼内容に応じて必要時だけ読む workflow と詳細ガイドを `.ai/skills/**` に置く。

既存の `.claude/skills/**` は Agent Skills 形式の共通 skill として移管する。既存の `.claude/commands/**` は Claude Code 固有 command として維持せず、次の共通 skill に変換する。

- `bdd`
- `commit`
- `review`
- `simplify`
- `verify`

共通 skill は `name` と `description` を持つ `SKILL.md` を入口にする。Claude Code 固有の `Task(...)`、`$ARGUMENTS`、tool 名、permission 記法には依存しない。実行主体が利用可能な tool で同じ目的を達成できる手順を書く。

`SKILL.md` は 500 行以内を基準とし、長い解説、例、チェックリストは `references/**` に分離する。既存ライセンスは対象 skill とともに保持する。

### Hooks

判断に任せず機械的に守る処理を `.ai/hooks/**` に置く。

- 編集後の自動 format
- 編集後の architecture guard と file lint
- `git commit` 前の品質ゲート
- PHP version consistency、生成 TypeScript、commit 前検査の回帰テスト

`.claude/settings.json` と `.codex/config.toml` は同じ `.ai/hooks/**` を呼ぶ。設定ファイル自体は lifecycle event や matcher を宣言する tool adapter なので、各 tool のディレクトリに残す。

## エージェント別の読み込み経路

### Claude Code

1. `CLAUDE.md` が `AGENTS.md` を import する。
2. `AGENTS.md` が `.ai/README.md` と必須 rule を案内する。
3. `.claude/rules` symlink により、変更対象に合う `.ai/rules/**` が path scoped rule としてロードされる。
4. `.claude/skills` symlink により、`.ai/skills/**` が skill として検出される。
5. `.claude/settings.json` が `.ai/hooks/**` を実行する。

### Codex

1. `AGENTS.md` が `.ai/README.md` と必須 rule を案内する。
2. `AGENTS.md` の変更対象別 routing に従い、該当する `.ai/rules/**` を読む。
3. `.agents/skills` symlink により、`.ai/skills/**` が skill として検出される。
4. trusted project の `.codex/config.toml` が `.ai/hooks/**` を実行する。

Codex の project hook は利用者による trust が必要である。`.ai/README.md` と `.codex/README.md` に `/hooks` で状態を確認し、必要なら承認する手順を記載する。

## Hook 入力の正規化

Claude Code と Codex は同系統の lifecycle event を持つが、編集 tool の入力形式が異なる。

- Claude Code の `Edit` / `Write`: `tool_input.file_path`
- Codex の `apply_patch`: `tool_input.command` 内の patch に複数ファイルを含み得る

共通 hook は stdin の JSON を正規化し、編集対象の repository-relative path 一覧を作ってから format と lint を実行する。Codex の session `cwd` または `CLAUDE_PROJECT_DIR` を起点に Git root を解決するため、リポジトリルートでも `src/` 配下でも同じ処理になる。

同じ event に複数ファイルが含まれる場合は各ファイルへ architecture guard を適用し、format と lint は対象言語ごとにまとめて実行できるようにする。

## エラー処理

- symlink の切断、正本の欠落、tool 固有ディレクトリへの共通本文再混入は構成テストと CI を失敗させる。
- 未知の hook 入力形式では対象ファイルを推測して変更せず、診断メッセージを返して安全に終了する。
- 編集後の informational lint が実行できない場合は編集を失敗扱いにしない。理由を通知し、最終品質ゲートで検出する。
- commit 前検査で Docker または必須 tool が利用できない場合は、検証不能のまま commit させず現状どおりブロックする。
- format は既存どおり best effort とし、architecture 違反は exit code 2 でエージェントへ返す。
- git 管理外の `.claude/settings.local.json` は個人設定であり、移行・削除・上書きしない。

## 参照更新

現在有効な次の参照を `.ai/**` に更新する。

- `AGENTS.md`
- `CLAUDE.md`
- `.codex/README.md`
- `.ai/README.md` と rule 間の相互参照
- skill 内の rule 参照
- `docs/specs/error-handling/requirements.md`
- `src/tests/Arch/**` と `src/tests/PHPStan/**` の規約参照コメント
- hook test を実行する GitHub Actions workflow

過去の経緯を記録する `docs/superpowers/specs/**` と `docs/superpowers/plans/**` は、当時の構成を示す履歴なので一括置換しない。

## 構成検査

共通化の退行を検出する shell test を追加する。

- `.claude/rules`、`.claude/skills`、`.agents/skills` の symlink target
- `.ai/rules/**` と `.ai/skills/**` の存在
- `.claude/commands` と `.claude/hooks` に共通本文が残っていないこと
- 現行ファイルに `.claude/rules/**` 参照が残っていないこと
- 全 skill の `name` / `description`、名前の一意性、参照先、行数
- 共通 skill に Claude Code 固有 API 表現が残っていないこと
- `AGENTS.md`、`CLAUDE.md`、`.codex/config.toml` から共通正本へ到達できること

## Hook 回帰テスト

既存の回帰テストを `.ai/hooks/tests/**` へ移し、次を追加する。

- Claude Code の単一ファイル `Edit` / `Write` 入力
- Codex の単一・複数ファイル `apply_patch` 入力
- `src/` から起動した場合の Git root 解決
- 未知の入力形式でファイルを変更しないこと
- PHP、TypeScript、生成物、architecture guard の既存動作を維持すること

## 品質ゲート

実装後に最低限、次を実行する。

```bash
bash scripts/check-php-version-consistency.sh
bash .ai/tests/agent-config-layout-test.sh
for test_file in .ai/hooks/tests/*-test.sh; do bash "$test_file"; done
docker compose exec app composer lint
docker compose exec app composer test
```

frontend source は変更しないため frontend の lint、type check、Vitest、Playwright は必須対象外とする。ただし skill や rule の検査が frontend command の不整合を検出した場合は、該当 command を個別に確認する。

## 受け入れ条件

1. 共通 rule、skill、hook の本文が `.ai/**` にだけ存在する。
2. `.claude/**` と `.codex/**` には tool 固有設定、README、共通正本への接続だけが存在する。
3. Claude Code と Codex が同じ 11 個の project skill を native discovery で検出できる構成になっている。
4. Claude Code の path scoped rules が `.ai/rules/**` を正本としてロードする。
5. Codex が `AGENTS.md` から変更対象別の `.ai/rules/**` へ到達できる。
6. Claude Code と Codex の hooks が同じ `.ai/hooks/**` を実行する。
7. hook 回帰テストが両 tool の入力形式を検証する。
8. 現行コード・文書に `.claude/rules/**` を正本として扱う参照が残らない。
9. symlink切れ、共通本文の再混入、skill形式の退行を CI が検出する。

## 対象外

- 個人用 `.claude/settings.local.json` の変更
- 過去の設計書・実装計画に記録された旧パスの書き換え
- application runtime の機能変更
- 新しい MCP server、外部 connector、subagent 定義の追加
