# Kiro Removal and Shared AI Rules Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (- [ ]) syntax for tracking.

**Goal:** Kiro とその参照を完全に削除し、既存要件と BDD/TDD 規約を保持したまま Claude Code / Codex 共通の .ai/ ルール構成へ移行する。

**Architecture:** Tool 非依存のルールは .ai/rules/、人間と AI が共有する機能要件は docs/specs/ に置く。CLAUDE.md と AGENTS.md は共通ルールへ接続する薄い入口とし、Kiro 固有メタデータと command は保持対象を先に移動した後で削除する。

**Tech Stack:** Markdown、Claude Code project instructions、Codex AGENTS.md、Pest/Gherkin documentation、Git

**Spec:** docs/superpowers/specs/2026-08-29-remove-kiro-shared-ai-rules-design.md

## Global Constraints

- .kiro/ と .claude/commands/kiro/ は最終状態で存在させない。
- .git、src/vendor、src/node_modules、移行記録の docs/superpowers/ を除く .kiro / kiro: 参照を0件にする。
- BDD、Gherkin、scenario() helper、1シナリオずつの Red → Green → Refactor は維持する。
- 既存要件は docs/specs/ へ移し、Kiro phase metadata の spec.json は移行しない。
- .ai/ を共通ルールの正本とし、tool 固有入口へ同じルール本文を複製しない。
- CLAUDE.md は .ai/rules/ を @import し、AGENTS.md は同じファイルを必読にする。
- アプリケーションの実行時コードとテストの振る舞いは変更しない。
- 削除対象は設計書に列挙したパスへ限定し、ユーザー所有の無関係な変更へ触れない。

---

## File Responsibility Map

- .ai/README.md: 共通ルールの配置方針と読み込みモデル。
- .ai/rules/workspace.md: Laravel/React テンプレート全体の共通原則。
- .ai/rules/testing.md: Kiro 非依存の BDD/TDD、要件配置、テスト境界。
- .ai/rules/error-handling.md: Issue #23 のエラー分類、復旧、安全性、表示責務。
- docs/specs/auth/requirements.md: 既存 auth Gherkin 要件の移動先。
- docs/specs/error-handling/requirements.md: Issue #23 Gherkin 要件の移動先。
- CLAUDE.md: Claude Code の薄い入口。
- AGENTS.md: Codex の薄い入口。
- .codex/README.md: Codex 固有ファイルの配置説明。
- .claude/commands/bdd.md: docs/specs/ を使う BDD command。
- .claude/skills/tdd-methodology/SKILL.md: Kiro 非依存の TDD skill。
- .claude/rules/testing/feature-test-policy.md: .ai/rules/testing.md との重複を解消するため削除。
- src/tests/Feature/Auth/AuthGwtTest.php と src/tests/Feature/Gwt/GwtExampleTest.php: 新しい要件文書への追跡リンク。
- .kiro/ と .claude/commands/kiro/: 削除対象。
- .dockerignore: 存在しなくなる .kiro entry のみ削除。

---

### Task 1: 要件文書を退避し、.ai/ 共通ルールを作成する

**Files:**
- Create: .ai/README.md
- Create: .ai/rules/workspace.md
- Create: .ai/rules/testing.md
- Create: .ai/rules/error-handling.md
- Move: .kiro/specs/auth/requirements.md → docs/specs/auth/requirements.md
- Move: .kiro/specs/error-handling/requirements.md → docs/specs/error-handling/requirements.md
- Modify: docs/specs/error-handling/requirements.md

**Interfaces:**
- Consumes: 承認済み設計と現在の .kiro 要件。
- Produces: 後続 task が参照する .ai/rules/ と docs/specs/。

- [ ] **Step 1: 退避対象が揃っていることを確認する**

Run:

    test -f .kiro/specs/auth/requirements.md
    test -f .kiro/specs/error-handling/requirements.md
    test -f .kiro/steering/bdd.md

Expected: exit code 0。いずれかが無ければ削除へ進まず、配置を再確認する。

- [ ] **Step 2: 要件文書を docs/specs/ へ移す**

Run:

    mkdir -p docs/specs/auth docs/specs/error-handling
    git mv .kiro/specs/auth/requirements.md docs/specs/auth/requirements.md
    mv .kiro/specs/error-handling/requirements.md docs/specs/error-handling/requirements.md

Expected: 2つの requirements.md が docs/specs/ 配下に存在する。error-handling requirements は未追跡なので通常の mv、auth requirements は追跡済みなので git mv を使う。

- [ ] **Step 3: error-handling requirements のKiro参照を更新する**

Use apply_patch for these exact changes:

    .kiro/steering/bdd.md と .claude/rules/testing/feature-test-policy.md
    → .ai/rules/testing.md

想定影響範囲から .kiro/ を削除し、.ai/、AGENTS.md、docs/specs/ を残す。spec.json と Kiro phase status への言及は追加しない。

Run:

    rg -n -i '\.kiro|kiro:' docs/specs

Expected: no matches, exit code 1。

- [ ] **Step 4: .ai/README.md を作る**

Use apply_patch with these required sections and statements:

    # AI Agent Shared Rules
    .ai/ は Claude Code、Codex など複数の AI エージェントで共有するルールの正本です。
    ## 必読
    - rules/workspace.md
    - rules/testing.md
    - rules/error-handling.md
    ## 読み込みモデル
    - Claude Code は CLAUDE.md の @import で自動ロードする。
    - Codex は AGENTS.md の必読指示から同じルールを読む。
    - .claude/ と .codex/ には tool 固有情報を置く。
    - docs/specs/ には人間とAIが共有する機能要件を置く。
    共通判断の変更は .ai/ の正本だけを更新する。

- [ ] **Step 5: .ai/rules/workspace.md を作る**

Use apply_patch and include:

    # Workspace Rules
    ## Communication
    - 内部では英語で考え、ユーザーへの応答とプロジェクト文書は日本語で書く。
    - 既存実装、既存ルール、ユーザー変更を尊重する。
    ## Laravel
    - Form Request / Precognition
    - Inertia props は Data DTO
    - Service class 禁止、Eloquent / Gateway / Concerns の境界
    - 詳細は .claude/rules/laravel/ と .claude/rules/php.md
    ## React
    - Pages を Inertia entry として維持
    - feature 固有実装は features/{feature}/
    - 2箇所以上の共有物だけ shared/
    - React Compiler 常時適用
    ## Quality Gates
    - PHP: Pint、PHPStan、Rector dry-run、Pest
    - Frontend: Biome、TypeScript、React Compiler、knip、jscpd、Vitest
    - User flow: Playwright
    - Testing は .ai/rules/testing.md
    - 異常系は .ai/rules/error-handling.md

- [ ] **Step 6: .ai/rules/testing.md を作る**

Use apply_patch with these normative rules:

    # Testing Rules
    ## Feature Test BDD
    - 要件は docs/specs/{feature}/requirements.md にGherkinで記載する。
    - Feature test変更前に対象scenarioとユーザー承認を確認する。
    - Feature testはscenario() helperを使う。
    - 1 scenarioずつRed → Green → Refactorし、失敗したまま次へ進まない。
    - describeはUC-XX、itはScenario X.Y形式にする。
    ## Test Boundaries
    - HTTP response / Inertia props: Pest Feature
    - component / hook: Vitest
    - 複数画面flow: Playwright
    - 宣言的構造: Pest Arch
    - 型解決が必要な呼び出し: PHPStan custom rule
    ## Exceptions
    - Unit、Arch、Vitest、Playwrightはscenario()を要求しない。

Kiro command と Kiro phase status は記載しない。

- [ ] **Step 7: .ai/rules/error-handling.md を作る**

Use apply_patch and preserve this exact matrix:

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

Follow it with these exact policies:

    - ページ全体か画面内操作か、復旧可能かで表示を決める。
    - retryは冪等または重複防止を保証できる処理だけに提供する。
    - API code、exception message、stack trace、内部IDをproduction UIに表示しない。
    - copy、action、URL、icon、semantic tokenはプロダクト側で差し替え可能にする。
    - 色だけで表現せず、ARIA、keyboard、focus managementを備える。
    - 通常画面とformはInertia、個別JSON通信はfeature内のuseHttpを使う。
    - global error interceptorは標準に含めない。

- [ ] **Step 8: Task 1 を検証する**

Run:

    test -f .ai/README.md
    test -f .ai/rules/workspace.md
    test -f .ai/rules/testing.md
    test -f .ai/rules/error-handling.md
    test -f docs/specs/auth/requirements.md
    test -f docs/specs/error-handling/requirements.md
    rg -n '^\| 入力・422 ' .ai/rules/error-handling.md
    rg -n -F 'docs/specs/{feature}/requirements.md' .ai/rules/testing.md
    git add .ai docs/specs docs/superpowers/specs/2026-08-29-remove-kiro-shared-ai-rules-design.md docs/superpowers/plans/2026-08-29-remove-kiro-shared-ai-rules.md
    git diff --cached --check

Expected: required files exist、matrix と requirements path が見つかり、whitespace error がない。

- [ ] **Step 9: Task 1 をコミットする**

Run:

    git commit -m "docs: AI共通ルールと機能要件の正本を追加する"

---

### Task 2: Claude Code と Codex の入口を接続する

**Files:**
- Modify: CLAUDE.md
- Create: AGENTS.md
- Create: .codex/README.md

**Interfaces:**
- Consumes: Task 1 の .ai/README.md と .ai/rules/。
- Produces: Claude Code と Codex が同じ共通ルールへ到達する入口。

- [ ] **Step 1: CLAUDE.md を薄い入口へ置き換える**

Use apply_patch with this complete content:

    # CLAUDE.md
    このファイルは Claude Code の入口です。AIエージェント共通ルールの正本は .ai/ に置きます。
    ## 共通ルール（自動ロード）
    @.ai/rules/workspace.md
    @.ai/rules/testing.md
    @.ai/rules/error-handling.md
    ## 必要時に参照
    - .ai/README.md — 配置方針と読み込みモデル
    - docs/specs/ — 機能要件とGherkin scenario
    - .claude/rules/ — Laravel、React、テストの詳細ルール
    - .claude/commands/ — Claude Code固有command
    - .claude/skills/ — Claude Code固有skill
    共通ルール変更時は原則 .ai/ を更新する。

- [ ] **Step 2: AGENTS.md を作る**

Use apply_patch with this complete content:

    # AGENTS.md
    このファイルは Codex の入口です。AIエージェント共通ルールの正本は .ai/ に置きます。
    ## 必読
    - .ai/README.md
    - .ai/rules/workspace.md
    - .ai/rules/testing.md
    - .ai/rules/error-handling.md
    ## 変更対象ごとの詳細ルール
    - Laravel / PHP: .claude/rules/laravel/ と .claude/rules/php.md
    - React / TypeScript: .claude/rules/frontend/ と .claude/rules/type-safety.md
    - Test / static analysis: .claude/rules/testing/
    ## Codex固有
    - Codex固有情報は .codex/ に置く。
    - 共通ルールは .ai/ を更新する。
    - generated TypeScript と Wayfinder生成物を手編集しない。

- [ ] **Step 3: .codex/README.md を作る**

Use apply_patch:

    # Codex Entry
    Codex固有のskill、設定、補足を置くディレクトリです。
    共通ルールの正本:
    - ../.ai/rules/workspace.md
    - ../.ai/rules/testing.md
    - ../.ai/rules/error-handling.md
    共通ルール変更時は .ai/ を更新する。

- [ ] **Step 4: 両入口を検証する**

Run:

    rg -n '.ai/rules/workspace.md' CLAUDE.md AGENTS.md .codex/README.md
    rg -n '.ai/rules/testing.md' CLAUDE.md AGENTS.md .codex/README.md
    rg -n '.ai/rules/error-handling.md' CLAUDE.md AGENTS.md .codex/README.md
    if rg -n -i '\.kiro|kiro:' CLAUDE.md AGENTS.md .codex .ai; then exit 1; fi
    git add CLAUDE.md AGENTS.md .codex/README.md
    git diff --cached --check

Expected: each rule is referenced by all entries。Kiro reference は0件。

- [ ] **Step 5: Task 2 をコミットする**

Run:

    git commit -m "chore: ClaudeとCodexでプロジェクトルールを共有する"

---

### Task 3: BDD/TDD の参照を Kiro から切り離す

**Files:**
- Modify: .claude/commands/bdd.md
- Modify: .claude/skills/tdd-methodology/SKILL.md
- Delete: .claude/rules/testing/feature-test-policy.md
- Modify: .claude/rules/frontend/testing.md
- Modify: .claude/rules/testing/architecture-tests.md
- Modify: src/tests/Feature/Auth/AuthGwtTest.php
- Modify: src/tests/Feature/Gwt/GwtExampleTest.php

**Interfaces:**
- Consumes: .ai/rules/testing.md と docs/specs/。
- Produces: Kiro commandなしで維持されるBDD command、TDD skill、要件追跡。

- [ ] **Step 1: /bdd command の参照先を置き換える**

Use apply_patch with exact replacements:

    .kiro/specs/{feature}/requirements.md  → docs/specs/{feature}/requirements.md
    .kiro/specs/$ARGUMENTS/requirements.md → docs/specs/$ARGUMENTS/requirements.md
    .kiro/steering/bdd.md                  → .ai/rules/testing.md

Example output は docs/specs/auth/requirements.md と src/tests/Feature/Auth/AuthGwtTest.php の2項目にする。spec.json item を削除する。/bdd、--spec-only、--test-only、承認gateは維持する。

- [ ] **Step 2: TDD methodology skill を更新する**

Use apply_patch:

    .kiro/specs/{feature}/requirements.md → docs/specs/{feature}/requirements.md
    .kiro/specs/post/requirements.md      → docs/specs/post/requirements.md

/kiro:spec-impl integration section は次へ置換する:

    ## AI Agent Workflow Integration
    1. docs/specs/{feature}/requirements.md のGherkin scenarioを読む。
    2. .ai/rules/testing.md の境界と承認条件を確認する。
    3. 対象scenarioを1件選びRed → Green → Refactorする。
    4. テスト成功後に次のscenarioへ進む。

- [ ] **Step 3: 重複する Feature test policy を削除する**

Run:

    git rm .claude/rules/testing/feature-test-policy.md

Expected: staged deletion。共通正本は .ai/rules/testing.md。

- [ ] **Step 4: 詳細ruleの参照先を更新する**

In .claude/rules/frontend/testing.md and .claude/rules/testing/architecture-tests.md replace:

    .claude/rules/testing/feature-test-policy.md
    → .ai/rules/testing.md

Pest Feature testはBDD必須、Vitest/Playwright/Archはscenario()不要という既存境界を維持する。

- [ ] **Step 5: GWT test の @see を更新する**

In both Feature test files replace:

    @see .kiro/specs/auth/requirements.md
    → @see docs/specs/auth/requirements.md

- [ ] **Step 6: Task 3 を検証する**

Run:

    if rg -n -i '\.kiro|kiro:' .claude/commands/bdd.md .claude/skills/tdd-methodology/SKILL.md .claude/rules/frontend/testing.md .claude/rules/testing/architecture-tests.md src/tests/Feature docs/specs .ai; then exit 1; fi
    rg -n 'docs/specs/auth/requirements.md' src/tests/Feature/Auth/AuthGwtTest.php src/tests/Feature/Gwt/GwtExampleTest.php
    rg -n 'scenario\(\)' .ai/rules/testing.md .claude/commands/bdd.md .claude/skills/tdd-methodology/SKILL.md
    git diff --check

Expected: Kiro referenceは0件。2つのtest commentが新要件を指し、scenario()規約が残る。

- [ ] **Step 7: Task 3 をコミットする**

Run:

    git add .claude/commands/bdd.md .claude/skills/tdd-methodology/SKILL.md .claude/rules/frontend/testing.md .claude/rules/testing src/tests/Feature/Auth/AuthGwtTest.php src/tests/Feature/Gwt/GwtExampleTest.php
    git commit -m "docs: BDDワークフローをKiroから切り離す"

---

### Task 4: Kiro 本体を削除し、残存参照0件を検証する

**Files:**
- Delete: .kiro/
- Delete: .claude/commands/kiro/
- Modify: .dockerignore

**Interfaces:**
- Consumes: Task 1〜3 の保持先と更新済み参照。
- Produces: Kiroのファイル、command、参照が存在しない最終状態。

- [ ] **Step 1: 削除前に保持先を確認する**

Run:

    test -f docs/specs/auth/requirements.md
    test -f docs/specs/error-handling/requirements.md
    test -f .ai/rules/testing.md
    git status --short

Expected: files exist。無関係なuser変更があれば削除前に分離する。

- [ ] **Step 2: 未追跡Kiro metadataを明示削除する**

Use apply_patch to delete only:

    .kiro/specs/error-handling/spec.json

要件本文は Task 1 で移動済み。

- [ ] **Step 3: 追跡済みKiro本体とcommandを削除する**

Run:

    git rm -r .kiro
    git rm -r .claude/commands/kiro

Expected: exact target directories are staged deletion。環境変数やglobを削除対象に使わない。

- [ ] **Step 4: .dockerignore の .kiro entry を削除する**

Use apply_patch to remove only the line:

    .kiro

- [ ] **Step 5: Kiroが完全に無いことを検証する**

Run:

    test ! -e .kiro
    test ! -e .claude/commands/kiro
    if rg -n --hidden -i '\.kiro|kiro:' . --glob '!.git/**' --glob '!src/vendor/**' --glob '!src/node_modules/**' --glob '!docs/superpowers/**'; then exit 1; fi

Expected: all commands exit 0、rgはno matches。

- [ ] **Step 6: 保持対象と変更範囲を検証する**

Run:

    test -f docs/specs/auth/requirements.md
    test -f docs/specs/error-handling/requirements.md
    test -f .ai/rules/workspace.md
    test -f .ai/rules/testing.md
    test -f .ai/rules/error-handling.md
    test -f CLAUDE.md
    test -f AGENTS.md
    git diff --check
    git diff --exit-code b96c422 -- src ':!src/tests/Feature/Auth/AuthGwtTest.php' ':!src/tests/Feature/Gwt/GwtExampleTest.php'

Expected: required files exist。srcには2つの@see comment以外の差分がない。

- [ ] **Step 7: 分類表と入口を最終確認する**

Run:

    rg -n -F 'docs/specs/{feature}/requirements.md' .ai/rules/testing.md .claude/commands/bdd.md .claude/skills/tdd-methodology/SKILL.md
    rg -n '^\| 復旧不能な500/503 ' .ai/rules/error-handling.md docs/specs/error-handling/requirements.md docs/superpowers/specs/2026-08-29-remove-kiro-shared-ai-rules-design.md
    rg -n '.ai/rules/workspace.md' CLAUDE.md AGENTS.md .codex/README.md
    rg -n '.ai/rules/testing.md' CLAUDE.md AGENTS.md .codex/README.md
    rg -n '.ai/rules/error-handling.md' CLAUDE.md AGENTS.md .codex/README.md

Expected: requirements path、分類表最終行、3つの共通rule参照がすべて見つかる。

- [ ] **Step 8: Task 4 をコミットする**

Run:

    git add .dockerignore
    git commit -m "chore: 使用していないKiro統合を削除する"

- [ ] **Step 9: 完了状態を確認する**

Run:

    git status --short
    git log --oneline -5

Expected: worktree clean。Task 1〜4のコミットと設計コミット b96c422 が履歴にある。
