---
globs: ["src/resources/js/**/*.test.ts","src/resources/js/**/*.test.tsx","src/playwright/**/*.ts","src/vitest.config.ts","src/playwright.config.ts"]
---

# Frontend Testing

フロントは 2 層でテストする。コンポーネントと hook は Vitest + Testing Library、画面をまたぐユーザーフローは Playwright。

## Vitest（コンポーネント / hook）

- 配置はコロケーション。`Components/TextInput.tsx` に対して `Components/TextInput.test.tsx`
- 実行は `npm run test:unit`（監視は `npm run test:unit:watch`）
- `vitest.config.ts` は `react-compiler.config.js` を読み込み、本番ビルドと同じ React Compiler の変換を通す。設定を別途書かない
- 環境は jsdom。`resources/js/test/setup.ts` で `@testing-library/jest-dom` を登録している

書くもの:

- ユーザーから見える振る舞い（表示、入力の反映、開閉、エラー表示）
- props の受け渡しと既定値
- ref / imperative API のような公開インターフェース

避けるもの:

- state 変数名や内部関数呼び出しなど実装詳細への依存
- クラス名や DOM 構造への依存（アクセシブルな role / label で取得する）
- スナップショットの大量生成

取得は `getByRole` / `getByLabelText` を優先する。操作は `fireEvent` ではなく `@testing-library/user-event` を使う。アニメーション付きの UI（Headless UI の `Transition` など）は即座に DOM から消えないので、`waitForElementToBeRemoved` などで待つ。

## Playwright（E2E）

- 配置は `playwright/**/*.spec.ts`
- 実行は `npm run test:e2e`。`php artisan serve` は Playwright の `webServer` が自動起動する
- 起動済みの環境（docker compose など）に対して実行する場合は `PLAYWRIGHT_BASE_URL` を渡す。その場合 `webServer` は起動しない
- CI は chromium のみ実行する。3 ブラウザ分のインストールが重いため。ローカルでは firefox / webkit も選べる

書くもの:

- ログイン、登録、プロフィール更新のような画面をまたぐフロー
- 認可（未認証で保護ページに入れないこと）

避けるもの:

- コンポーネント単体の分岐網羅（Vitest 側の役割）
- DB の特定レコードへの依存。ユーザーを作るテストは実行ごとに一意なメールアドレスを使う

## Laravel 側のテストとの境界

- HTTP レスポンスや Inertia props の検証は Pest の Feature テスト（BDD フロー必須。`.ai/rules/testing.md`）
- 実装構造の検査は arch テスト（`.claude/rules/testing/architecture-tests.md`）
- フロントの Vitest / Playwright は BDD フローの対象外。requirements.md や `scenario()` ヘルパーは不要
