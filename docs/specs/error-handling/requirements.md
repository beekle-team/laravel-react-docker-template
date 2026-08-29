# 共通エラーハンドリング基盤 - 要件定義

## 概要

Laravel / Inertia / React を使うプロジェクトで繰り返し必要になる異常系の分類、表示方法、復旧導線をテンプレートとして提供する。

especially-me で運用しているエラーハンドリング構造を参照しつつ、プロダクト固有のデザイン、文言、URL、業務コードを持ち込まない。入力エラー、ドメインエラー、ネットワークエラー、認証・セッションエラー、権限エラー、データ不存在、システムエラーを同じ判断基準で扱い、各プロジェクトは見た目と文言だけを差し替えられるようにする。

また、エラーハンドリング規約を Claude Code と Codex の双方が同じ正本から参照できるようにし、AI エージェントごとのルール重複と内容の乖離を防ぐ。

### 設計概要

| 項目 | 内容 |
| --- | --- |
| **ユースケース数** | **7件** |
| **シナリオ数** | **22件** |
| **基本導線** | Inertia page visit / Inertia form |
| **個別 JSON 通信** | feature 境界内の `useHttp` |
| **UI 方針** | semantic token と差し替え可能な copy / action |
| **AI ルール正本** | `.ai/` |

### 目的

1. HTTP status だけでなく、ページ全体の失敗か画面内操作の失敗か、復旧可能かどうかで表示方法を決める。
2. ユーザーに原因を明確な言葉で伝え、次に取れる解決策を必ず提示する。
3. API code、例外メッセージ、stack trace などの内部情報を本番 UI に露出しない。
4. デザインを固定せず、semantic token、props、action contract でプロダクト側から差し替えられるようにする。
5. Claude Code と Codex が同じ規約を参照し、どちらで実装しても同じ判断になるようにする。

### エラー分類と既定の表示

この表はテンプレートのエラーハンドリング規約に残す。実装後の運用上の正本は `.ai/rules/error-handling.md` とする。

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

### 用語

- **ページエラー**: URL へ遷移した結果、ページ全体を表示できない状態。
- **操作エラー**: 表示中のページは維持できるが、そのページ内で開始した操作を完了できない状態。
- **ドメインエラー**: 入力形式ではなく、現在の業務状態やビジネスルールにより操作を受け付けられない状態。
- **安全な再試行**: GET などの冪等な処理、または idempotency key 等により重複実行を防げる処理の再実行。
- **復旧不能**: 現在の画面状態のままユーザー操作を継続できず、エラーページへ切り替える必要がある状態。

### 対象外

- especially-me 固有の色、余白、角丸、shadow、icon、Figma token。
- especially-me 固有の日本語文言、ログイン URL、ホーム URL、検索 URL、問い合わせ URL。
- API の error code と表示文言のプロジェクト固有マッピング。
- Sentry 等の外部監視サービスそのものの導入。
- 個別 API / XHR に対するアプリ全体のグローバル interceptor。

---

## 1. ユースケース一覧

### 1.1 全体マップ

```text
[共通エラーハンドリング基盤]
├─ UC-01: 入力エラーとドメインエラーを通知する
├─ UC-02: 画面内操作の失敗から復旧する
├─ UC-03: ページ全体の HTTP エラーを安全に表示する
├─ UC-04: クライアント実行時エラーから白画面を防ぐ
├─ UC-05: メッセージ・デザイン・アクセシビリティを統一する
├─ UC-06: Inertia と個別 JSON 通信の責務を分離する
└─ UC-07: Claude Code と Codex で規約を共有する
```

### 1.2 優先度と概要

| ID | ユースケース名 | 優先度 | シナリオ数 |
| --- | --- | --- | --- |
| UC-01 | 入力エラーとドメインエラーを通知する | 最高 | 2 |
| UC-02 | 画面内操作の失敗から復旧する | 最高 | 6 |
| UC-03 | ページ全体の HTTP エラーを安全に表示する | 最高 | 5 |
| UC-04 | クライアント実行時エラーから白画面を防ぐ | 高 | 2 |
| UC-05 | メッセージ・デザイン・アクセシビリティを統一する | 高 | 3 |
| UC-06 | Inertia と個別 JSON 通信の責務を分離する | 高 | 2 |
| UC-07 | Claude Code と Codex で規約を共有する | 最高 | 2 |

---

## 2. ユースケース詳細

### UC-01: 入力エラーとドメインエラーを通知する

#### 概要

ユーザーが修正できる入力不備と、業務状態による操作拒否を別の表示方法で通知する。

#### アクター

- フォームを入力するユーザー
- 画面内操作を実行するユーザー

#### ビジネス価値

ユーザーが修正箇所と次の行動を迷わず判断でき、同じ種類のエラーが画面ごとに異なる方法で表示されることを防ぐ。

#### 基本フロー

**Scenario 1.1: 422 validation error をフィールド単位で表示する**

```gherkin
Given Inertia form から Form Request を使う更新処理を送信する
And 入力値に validation error がある
When Laravel が validation error を返す
Then 該当フィールドの近くに inline error が表示される
And 該当フィールドが semantic error style で強調される
And aria-invalid と aria-describedby でエラーとの関連が示される
And toast、modal、error page へは切り替わらない
```

**Scenario 1.2: domain error を統一された toast で表示する**

```gherkin
Given 入力形式は正しい
And 現在の業務状態では操作を実行できない
When feature が domain error をユーザー向けメッセージへ変換する
Then 統一された error toast が表示される
And API code や例外メッセージは表示されない
And ユーザーが内容を修正して再実行するための説明が表示される
```

#### 受け入れ基準

- [ ] validation error は inline に限定する。
- [ ] domain error の既定表示は共通 error toast とする。
- [ ] domain error を validation error として表示しない。
- [ ] feature が内部エラーをユーザー向けメッセージへ変換してから共通 UI を呼ぶ。

---

### UC-02: 画面内操作の失敗から復旧する

#### 概要

現在のページを維持できる異常では、操作箇所、toast、modal のいずれかを使い、ユーザーが安全に復旧できる導線を提供する。

#### アクター

- 画面内操作を実行するユーザー

#### ビジネス価値

復旧可能な異常でページ全体を失わず、重複送信や行き止まりを防ぎながら操作を継続できる。

#### 基本フロー

**Scenario 2.1: network error の操作箇所に再試行を表示する**

```gherkin
Given 画面内の通信処理を実行している
When timeout、offline、接続切断などの network error が発生する
Then 操作箇所内または共通 error toast に明確な説明が表示される
And 安全に再試行できる場合は再試行 action が表示される
And 安全性を保証できない更新処理は自動再試行されない
```

**Scenario 2.2: authentication error からログインへ移動できる**

```gherkin
Given ユーザーが画面内操作を実行する
When session 切れ等により 401 authentication error が返る
Then authentication error modal が表示される
And configurable なログインページへの action が表示される
And 現在の操作を継続できない理由が説明される
```

**Scenario 2.3: 419 page expired を前画面へ戻して通知する**

```gherkin
Given ユーザーが期限切れの CSRF token で Inertia 操作を送信する
When Laravel が 419 response を生成する
Then 前画面へ redirect される
And 再送信を促す one-time flash message が返る
And 入力を再確認して操作をやり直せる
```

**Scenario 2.4: operation forbidden を modal で表示する**

```gherkin
Given ユーザーは現在のページを閲覧できる
When 画面内操作だけに必要な権限がない
Then operation forbidden modal が表示される
And 戻るまたは一覧へ移動する action が表示される
And ページ全体の 403 error page へは切り替わらない
```

**Scenario 2.5: 操作対象が存在しない場合に復旧導線を表示する**

```gherkin
Given ユーザーが表示中のページで対象データを操作する
And 対象データが削除済みまたは参照不能である
When feature が operation-scoped 404 を受け取る
Then data not found modal または共通 error toast が表示される
And 再読込または一覧へ移動する action が表示される
And ページ自体の 404 error page へは切り替わらない
```

**Scenario 2.6: 復旧可能な system error を toast で表示する**

```gherkin
Given 現在のページは継続して利用できる
When 画面内操作で一時的な system error が発生する
Then 共通 error toast が表示される
And 安全に実行できる場合だけ再試行 action が提供される
And 内部エラー情報は表示されない
```

#### 受け入れ基準

- [ ] `ErrorDialogProvider` と `useErrorDialogs()` から authentication、operation forbidden、data not found の modal を開ける。
- [ ] network error 用の操作箇所内 component は retry 状態と action を受け取れる。
- [ ] one-time flash message をアプリ全体で一貫して表示できる。
- [ ] retry は呼び出し側が安全性を判断して明示的に渡す。
- [ ] modal routing は標準導入せず、URL・履歴・deep link が必要な feature だけで検討する。

---

### UC-03: ページ全体の HTTP エラーを安全に表示する

#### 概要

非 JSON の Laravel exception response を Inertia error page へ接続し、ページを継続できない異常でもユーザーが次の行動を選べるようにする。

#### アクター

- Web ページへアクセスするユーザー
- ローカル環境で障害を調査する開発者

#### ビジネス価値

production で Laravel の HTML error response が Inertia の開発用 modal に表示されることや、機密情報が露出することを防ぐ。

#### 基本フロー

**Scenario 3.1: ページ権限の 403 を Inertia error page で表示する**

```gherkin
Given ユーザーにページを閲覧する権限がない
When 非 JSON request が 403 response になる
Then Inertia の Forbidden page が HTTP 403 のまま表示される
And configurable なホームへ戻る action が表示される
```

**Scenario 3.2: ページ不存在の 404 を Inertia error page で表示する**

```gherkin
Given 存在しない URL または削除済みページへアクセスする
When 非 JSON request が 404 response になる
Then Inertia の NotFound page が HTTP 404 のまま表示される
And ホームへ戻る action が表示される
And search URL が設定されている場合だけ検索 action が表示される
```

**Scenario 3.3: production の 500 と 503 を System page で表示する**

```gherkin
Given application environment が local または testing ではない
When 非 JSON request が 500 または 503 response になる
Then Inertia の System page が元の HTTP status のまま表示される
And 再読込、ホーム、設定済みの場合は問い合わせの action が表示される
And stack trace、例外メッセージ、内部 ID は表示されない
```

**Scenario 3.4: local と testing では Laravel の debug response を維持する**

```gherkin
Given application environment が local または testing である
When request が 500 または 503 response になる
Then Laravel の標準 debug response が維持される
And custom System page へ置き換えられない
```

**Scenario 3.5: JSON request には Inertia error page を返さない**

```gherkin
Given request が JSON response を期待している
When request が 403、404、419、500、503 のいずれかになる
Then Laravel または feature の JSON error contract が維持される
And Inertia error page や HTML redirect へ変換されない
```

#### 受け入れ基準

- [ ] Inertia 3 の `Inertia::handleExceptionsUsing()` を標準の接続 API として使う。
- [ ] 403、404、500、503 はページ種別へ明示的に mapping する。
- [ ] 500、503 の debug response は local/testing で維持する。
- [ ] `expectsJson()` 相当の判定で JSON request を除外する。
- [ ] error page が必要とする home、search、support の URL と copy は差し替え可能にする。

---

### UC-04: クライアント実行時エラーから白画面を防ぐ

#### 概要

React component tree の render error を root error boundary で受け、操作不能な白画面を共通の system error view に置き換える。

#### アクター

- React 画面を利用するユーザー
- 障害を監視する開発者

#### ビジネス価値

JavaScript runtime error が発生しても、ユーザーに復旧導線を提示し、将来の監視サービスへ通知できる接続点を確保する。

#### 基本フロー

**Scenario 4.1: React render error を system fallback へ切り替える**

```gherkin
Given application root が React error boundary で wrap されている
When child component の render 中に例外が発生する
Then 白画面ではなく共通 system error view が表示される
And 再読込とホームへ戻る action が表示される
And production UI に stack trace は表示されない
```

**Scenario 4.2: クライアント例外を監視処理へ渡せる**

```gherkin
Given React error boundary に onError callback が設定されている
When child component の render error を捕捉する
Then error と component information が callback へ渡される
And 外部監視サービスを導入していなくても fallback UI は動作する
```

#### 受け入れ基準

- [ ] root に configurable な React error boundary を置く。
- [ ] HTTP error handling と React error boundary の責務を混ぜない。
- [ ] development 以外では stack trace を表示しない。
- [ ] Inertia の開発用 error modal は native dialog option を有効にする。

---

### UC-05: メッセージ・デザイン・アクセシビリティを統一する

#### 概要

すべての異常系 UI が同じ安全性、差し替え可能性、アクセシビリティ基準を満たすようにする。

#### アクター

- エラー内容を確認するユーザー
- テンプレートから新しいプロダクトを作る開発者・デザイナー

#### ビジネス価値

各プロダクトがブランドを適用できる一方、情報漏洩や操作不能な UI を再発させない。

#### 基本フロー

**Scenario 5.1: ユーザー向けメッセージに原因と解決策を含める**

```gherkin
Given error UI を表示する
When title、message、action を構成する
Then ユーザーが理解できる言葉で状態を説明する
And 次に取れる解決策を action または本文で提示する
And API code、exception message、stack trace をそのまま表示しない
```

**Scenario 5.2: プロダクト固有デザインへ差し替える**

```gherkin
Given テンプレートの error UI component を利用する
When プロダクトの design token、copy、icon、URL を設定する
Then component の振る舞いを変更せずに見た目と文言を差し替えられる
And component 内にプロダクト固有の raw color、固定 URL、業務文言を追加する必要がない
```

**Scenario 5.3: 色だけに依存せずエラー状態を伝える**

```gherkin
Given error UI が表示される
When keyboard または assistive technology で操作する
Then semantic element、role、label、focus management から状態と action を理解できる
And error state は色だけで表現されない
And modal は focus trap と close policy を持つ
```

#### 受け入れ基準

- [ ] semantic CSS variables / Tailwind token を使い、プロダクト固有の raw value を共通 component に固定しない。
- [ ] title、message、action label、URL は props または設定から差し替え可能にする。
- [ ] modal、toast、inline error、error page は適切な ARIA semantics と keyboard 操作を持つ。
- [ ] toast だけに依存して重要な操作を阻害しない。

---

### UC-06: Inertia と個別 JSON 通信の責務を分離する

#### 概要

通常の画面遷移・フォーム更新は Inertia に統一し、個別 JSON 通信が必要な feature だけが feature 境界内で専用の処理を持つ。

#### アクター

- 新しい feature を実装する開発者・AI エージェント

#### ビジネス価値

アプリ全体の interceptor による意図しない挙動変更を避け、エラー処理の責務を追跡しやすくする。

#### 基本フロー

**Scenario 6.1: 通常の画面操作を Inertia で処理する**

```gherkin
Given page visit または通常の form submission を実装する
When Laravel と通信する
Then Inertia router、Form、useForm、Precognition のいずれかを使用する
And validation と exception は Inertia の標準 lifecycle で処理する
And 個別 Axios client や global error interceptor を追加しない
```

**Scenario 6.2: 個別 JSON 通信を feature 内で処理する**

```gherkin
Given page navigation を伴わない JSON 通信が feature に必要である
When endpoint を呼び出す
Then feature 境界内で Inertia 3 の useHttp または同等の専用 adapter を使用する
And 422、network、authentication、domain error を feature の表示契約へ変換する
And 他 feature の通信へ影響する global interceptor は導入しない
```

#### 受け入れ基準

- [ ] Inertia を基本導線とする方針を AI 共通ルールと README に明記する。
- [ ] JSON 通信は feature 内に閉じる。
- [ ] 422 の表示先は通信方式にかかわらず入力 field の inline error とする。
- [ ] global interceptor はテンプレートの標準に含めない。

---

### UC-07: Claude Code と Codex で規約を共有する

#### 概要

AI エージェント共通ルールを `.ai/` に集約し、Claude Code と Codex の入口から同じ正本を参照する。

#### アクター

- Claude Code を使う開発者
- Codex を使う開発者
- テンプレートを保守する開発者

#### ビジネス価値

利用する AI エージェントによって設計判断が変わることと、同じルールを複数箇所で更新する保守負担を防ぐ。

#### 基本フロー

**Scenario 7.1: Claude Code と Codex が同じエラーハンドリング規約を読む**

```gherkin
Given 共通ルールの正本が .ai/rules/error-handling.md にある
When Claude Code または Codex が error handling を含むタスクを開始する
Then どちらも同じ分類表と実装方針を参照する
And tool 固有入口に同じルール本文を複製しない
```

**Scenario 7.2: tool 固有入口から共通ルールへ到達する**

```gherkin
Given repository root に CLAUDE.md と AGENTS.md がある
When Claude Code が起動する
Then CLAUDE.md の @import から必須の .ai/rules を自動ロードする
When Codex が起動する
Then AGENTS.md の必読指示に従って同じ .ai/rules を読む
And .claude と .codex には tool 固有情報だけを置く
```

#### 受け入れ基準

- [ ] `.ai/README.md` に共通ルールの配置と読み込みモデルを記載する。
- [ ] `.ai/rules/workspace.md` にプロジェクト共通ルールを置く。
- [ ] `.ai/rules/error-handling.md` に本要件の分類表と実装ルールを置く。
- [ ] `CLAUDE.md` は必須共通ルールを `@import` する。
- [ ] `AGENTS.md` は Codex の入口として同じ共通ルールを必読にする。
- [ ] 既存 `.claude/rules/**` の native auto-load を維持し、Codex から必要時に参照する導線を設ける。
- [ ] 共通ルール変更時は原則 `.ai/` の正本だけを更新する。

---

## 3. 品質保証

### 3.1 Laravel Feature テスト

Feature テストは `.ai/rules/testing.md` に従い、ユーザー承認後に `scenario()` helper を使って1シナリオずつ Red → Green → Refactor する。

最低限、次の振る舞いを自動テストする。

- 非 JSON の 403 が Inertia Forbidden page になる。
- 非 JSON の 404 が Inertia NotFound page になる。
- 419 が前画面への redirect と one-time flash になる。
- JSON request が Inertia page に変換されない。
- local/testing の 500/503 が Laravel 標準 response を維持する。

### 3.2 Vitest

- error dialog provider と各 semantic dialog の公開 contract。
- network error の retry action と retrying state。
- error page の必須 action と任意 action。
- React error boundary の fallback、production での内部情報非表示、`onError` callback。
- error toast と flash message の表示。

### 3.3 静的検査

- TypeScript、Biome、React Compiler、knip、jscpd を通す。
- PHP は Pint、PHPStan、Rector dry-run を通す。
- 共通 component に `any` とプロダクト固有 API response type を持ち込まない。

---

## 4. 想定影響範囲

- `.ai/README.md`
- `.ai/rules/workspace.md`
- `.ai/rules/error-handling.md`
- `AGENTS.md`
- `CLAUDE.md`
- `.codex/README.md`
- `src/app/Providers/AppServiceProvider.php`
- `src/resources/js/app.tsx`
- `src/resources/js/Pages/Errors/**`
- `src/resources/js/shared/components/errors/**`
- `src/resources/js/shared/lib/errorToast.ts`
- `src/resources/css/app.css`
- `src/tests/Feature/ErrorHandling/**`
- `src/resources/js/**/*.test.tsx`
- `src/README.md`

## 5. 参照

- GitHub Issue: `beekle-team/laravel-react-docker-template#23`
- especially-me PR: `beekle-team/especially-me#9`
- Inertia v3 Error Handling
- Inertia v3 Flash Data
- Inertia v3 Validation
- Inertia v3 HTTP Requests / `useHttp`
- zutool-flutter-v1 の `.ai/`、`CLAUDE.md`、`AGENTS.md` 構成
