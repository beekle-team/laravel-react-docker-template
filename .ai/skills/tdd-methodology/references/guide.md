# TDD/BDD Methodology

Test-Driven Development と Behavior-Driven Development の実践ガイド。
**Pest v4の関数型構文（`it`/`describe`）を使用したBDDスタイル**を標準とする。

**Keywords**: tdd, bdd, test-first, gherkin, requirements, given-when-then, red-green-refactor, pest, vitest, playwright, e2e, browser-test, it, describe

## Core Principles

### 1. Test-First Development (TDD Cycle)

```
RED → GREEN → REFACTOR

1. RED: Write a failing test first
2. GREEN: Write minimal code to pass the test
3. REFACTOR: Improve code while keeping tests green
```

**Rules:**
- NEVER write implementation code without a failing test
- Each test should test ONE behavior
- Tests must be independent and repeatable

### 2. Feature テストでは scenario() ヘルパー必須

**🔴 CRITICAL: Feature テスト（tests/Feature/）では必ず `scenario()` ヘルパーを使用すること**

```php
// ✅ 正しい: scenario() ヘルパーを使用
it('Scenario 1.1: ユーザー登録できる', function () {
    scenario('ユーザー登録フロー')
        ->given('有効なユーザーデータ', function () { ... })
        ->when('登録APIを呼び出す', function ($data) { ... })
        ->then('成功する', function ($response) { ... })
        ->run();
});

// ❌ 間違い: scenario() なしの直接テスト
it('registers a user', function () {
    $response = $this->post('/register', [...]);
    expect(...)->toBe(...);
});
```

**例外（scenario() 不要）:**
- `tests/Unit/` - ユニットテスト
- `tests/Browser/` - ブラウザテスト

### 3. Requirements Documentation (BDD)

**CRITICAL RULE: Undocumented Implementation Prevention**

When implementing ANY feature or behavior:

1. **Check** `docs/specs/{feature}/requirements.md` for existing requirement
2. **If NOT documented**: Add requirement in Gherkin format BEFORE implementing
3. **If documented**: Proceed with implementation

### Gherkin Format

All requirements MUST be documented in Gherkin format:

```gherkin
### REQ-XXX: [Requirement Title]

**Scenario**: [Scenario Name]
  Given [initial context]
  When [action is performed]
  Then [expected outcome]
  And [additional outcome if needed]
```

### Example

```gherkin
### REQ-POST-001: Post Publication

**Scenario**: Successful post publication
  Given a user has written a blog post
  And the post has a title and content
  When the user clicks "Publish"
  Then the post status changes to "published"
  And the published_at timestamp is set
  And the user is redirected to the post page

**Scenario**: Draft post cannot be published without title
  Given a user has a draft post without a title
  When the user attempts to publish
  Then an error message "Title is required" is displayed
  And the post remains in draft status
```

## Test Organization

### Backend Tests (Pest)
```
tests/
├── Feature/           # Integration tests (HTTP, database)
│   ├── Post/          # Post-related tests
│   ├── Auth/          # Authentication tests
│   └── User/          # User management tests
└── Unit/              # Unit tests (isolated logic)
    ├── Models/        # Model logic tests
    └── Helpers/       # Helper function tests
```

### Frontend Tests (Vitest)

テスト対象と同じ場所に `*.test.tsx` / `*.test.ts` を置く。

```
resources/js/
├── Components/
│   ├── TextInput.tsx
│   └── TextInput.test.tsx    # 対象のとなりに置く
├── features/{feature}/
│   ├── hooks/useThing.ts
│   └── hooks/useThing.test.ts
└── test/
    └── setup.ts              # jest-dom の登録
```

### E2E Tests (Playwright)

```
playwright/
├── home.spec.ts       # ランディングページ
└── auth.spec.ts       # 認証フロー
```

## Testing Strategy

### Backend (Laravel/Pest)

**What to Test:**

| Layer | Test Type | Priority |
|-------|-----------|----------|
| Controllers | Feature tests (HTTP) | High |
| Models | Unit tests (relationships, scopes) | High |
| Jobs | Feature tests (queue assertions) | Medium |
| FormRequests | Feature tests (validation) | Medium |

**Pest Test Examples:**

```php
// Feature test - scenario() ヘルパー必須
describe('UC-01: 投稿公開', function () {
    it('Scenario 1.1: 投稿を正常に公開できる', function () {
        scenario('投稿公開フロー')
            ->given('ログイン済みユーザーが存在する', function () {
                return User::factory()->create();
            })
            ->and('下書き投稿がある', function (User $user) {
                $post = Post::factory()
                    ->for($user)
                    ->draft()
                    ->create();

                return ['user' => $user, 'post' => $post];
            })
            ->when('公開APIを呼び出す', function (array $context) {
                $this->actingAs($context['user']);

                return $this->post(route('posts.publish', $context['post']));
            })
            ->then('投稿ページにリダイレクトされる', function ($response) {
                $response->assertRedirect();
            })
            ->and('ステータスがpublishedになる', function ($response) {
                $post = Post::latest()->first();
                expect($post->status)->toBe('published');
                expect($post->published_at)->not->toBeNull();
            })
            ->run();
    });

    it('Scenario 1.2: タイトルなしでは公開できない', function () {
        scenario('タイトル必須バリデーション')
            ->given('ログイン済みユーザーが存在する', function () {
                return User::factory()->create();
            })
            ->and('タイトルなしの下書き投稿', function (User $user) {
                $post = Post::factory()
                    ->for($user)
                    ->create(['title' => null]);

                return ['user' => $user, 'post' => $post];
            })
            ->when('公開APIを呼び出す', function (array $context) {
                $this->actingAs($context['user']);

                return $this->post(route('posts.publish', $context['post']));
            })
            ->then('バリデーションエラーになる', function ($response) {
                $response->assertSessionHasErrors(['title']);
            })
            ->and('ステータスはdraftのまま', function ($response) {
                $post = Post::latest()->first();
                expect($post->status)->toBe('draft');
            })
            ->run();
    });
});

// Unit test - Model（scenario不要）
it('generates slug from title', function () {
    $post = Post::factory()->create([
        'title' => 'My First Blog Post',
    ]);

    expect($post->slug)->toBe('my-first-blog-post');
});
```

**重要: Feature テストは必ず `scenario()` ヘルパーを使用すること。Unit テストは不要。**

### Frontend (Vitest + Testing Library)

```typescript
// Component test
import { render, screen } from '@testing-library/react';
import { PostCard } from '@/components/PostCard';

describe('PostCard', () => {
  it('displays post title and excerpt', () => {
    const post = {
      id: 1,
      title: 'Test Post',
      excerpt: 'This is a test excerpt',
    };

    render(<PostCard post={post} />);

    expect(screen.getByText('Test Post')).toBeInTheDocument();
    expect(screen.getByText('This is a test excerpt')).toBeInTheDocument();
  });
});

// Hook test
import { renderHook, act } from '@testing-library/react';
import { useForm } from '@/hooks/useForm';

describe('useForm', () => {
  it('manages form state correctly', () => {
    const { result } = renderHook(() => useForm({ title: '' }));

    act(() => {
      result.current.setData('title', 'New Title');
    });

    expect(result.current.data.title).toBe('New Title');
  });
});
```

### E2E Browser Tests (Pest v4 + Playwright)

> このプロジェクトの E2E は Playwright の runner (`playwright/**/*.spec.ts`, `npm run test:e2e`) で実行する。Pest v4 の Browser Testing は未セットアップなので、以下は参考情報として扱い、実際のテストは `.ai/rules/frontend/testing.md` に従って `playwright/` 配下に書く。

Pest v4のBrowser Testing機能を使用して、実際のブラウザでE2Eテストを実行。

**テストファイル配置:**
```
tests/
├── Browser/              # E2E Browser Tests
│   ├── Post/             # 投稿フロー
│   ├── Auth/             # 認証フロー
│   └── Dashboard/        # ダッシュボード
├── Feature/              # HTTP Feature Tests
└── Unit/                 # Unit Tests
```

#### 基本的なBrowser Test

```php
// tests/Browser/Post/PublishPostTest.php
<?php

use App\Models\User;
use App\Models\Post;

it('publishes a post through the UI', function () {
    $user = User::factory()->create();
    $post = Post::factory()->for($user)->draft()->create();

    $this->actingAs($user);

    visit(route('posts.edit', $post))
        ->assertSee('Edit Post')
        ->fill('title', 'Updated Title')
        ->fill('content', 'Updated content here...')
        ->click('Publish')
        ->assertPathIs('/posts/' . $post->slug)
        ->assertSee('Updated Title')
        ->assertSee('Published');
});

it('shows validation error for empty title', function () {
    $user = User::factory()->create();
    $post = Post::factory()->for($user)->draft()->create();

    $this->actingAs($user);

    visit(route('posts.edit', $post))
        ->fill('title', '')
        ->click('Publish')
        ->assertSee('The title field is required');
});
```

#### フォーム操作

```php
it('allows user to update profile', function () {
    $user = User::factory()->create();

    $this->actingAs($user);

    visit(route('profile.edit'))
        ->assertSee('Edit Profile')
        ->fill('name', 'New Name')
        ->fill('email', 'new@example.com')
        ->select('timezone', 'Asia/Tokyo')
        ->check('notifications_enabled')
        ->click('Save')
        ->assertSee('Profile updated successfully');

    expect($user->fresh()->name)->toBe('New Name');
});
```

#### JavaScript操作（モーダル、ドロップダウン等）

```php
it('opens delete confirmation modal', function () {
    $user = User::factory()->create();
    $post = Post::factory()->for($user)->create();

    $this->actingAs($user);

    visit(route('posts.show', $post))
        ->click('[data-testid="delete-button"]')
        ->waitFor('[data-testid="confirmation-modal"]')
        ->assertSee('Are you sure you want to delete this post?')
        ->click('Confirm')
        ->assertPathIs('/posts')
        ->assertSee('Post deleted successfully');
});
```

#### 複数ブラウザ・デバイス対応

```php
it('works on mobile viewport', function () {
    $user = User::factory()->create();

    $this->actingAs($user);

    visit(route('dashboard'))
        ->resize(375, 812)  // iPhone X
        ->assertSee('Dashboard')
        ->click('[data-testid="mobile-menu-toggle"]')
        ->waitFor('[data-testid="mobile-menu"]')
        ->assertSee('Posts');
});

it('supports dark mode', function () {
    $user = User::factory()->create();

    $this->actingAs($user);

    visit(route('dashboard'))
        ->switchColorScheme('dark')
        ->screenshot('dashboard-dark-mode');
});
```

#### エラーチェック

```php
it('has no JavaScript errors on the page', function () {
    $user = User::factory()->create();

    $this->actingAs($user);

    visit(route('dashboard'))
        ->assertNoJavascriptErrors()
        ->assertNoConsoleLogs(['error', 'warning']);
});
```

#### Smoke Tests（全ページ確認）

```php
// tests/Browser/SmokeTest.php
it('loads all public pages without errors', function () {
    $pages = visit([
        route('welcome'),
        route('login'),
        route('register'),
    ]);

    $pages
        ->assertNoJavascriptErrors()
        ->assertNoConsoleLogs();
});

it('loads all authenticated pages without errors', function () {
    $user = User::factory()->create();

    $this->actingAs($user);

    $pages = visit([
        route('dashboard'),
        route('posts.index'),
        route('profile.edit'),
    ]);

    $pages
        ->assertNoJavascriptErrors()
        ->assertNoConsoleLogs();
});
```

#### スクリーンショット・デバッグ

```php
it('captures visual state for debugging', function () {
    $user = User::factory()->create();

    $this->actingAs($user);

    visit(route('dashboard'))
        ->screenshot('dashboard-page')  // storage/app/screenshots/に保存
        ->pause(1000)  // 1秒待機（デバッグ用）
        ->assertSee('Dashboard');
});
```

#### Browser Test実行

```bash
# 全Browser Testsを実行
php artisan test tests/Browser/

# 特定のテストファイル
php artisan test tests/Browser/Post/PublishPostTest.php

# フィルタ
php artisan test --filter="publishes a post"

# ヘッドレスモードをオフ（ブラウザを表示）
HEADLESS=false php artisan test tests/Browser/
```

## Running Tests

### Backend (Pest)

```bash
# Run all tests
composer test

# Run specific file
php artisan test tests/Feature/Post/PublishPostTest.php

# Run with filter
php artisan test --filter=PublishPostTest

# Run with coverage
php artisan test --coverage

# Run in parallel
php artisan test --parallel
```

### Frontend (Vitest)

```bash
# Run all tests
npm run test:unit

# Watch mode
npm run test:unit:watch

# Specific file
npm run test:unit -- TextInput
```

### E2E (Playwright)

```bash
# Run all specs (php artisan serve は Playwright が自動起動する)
npm run test:e2e

# Chromium だけ
npx playwright test --project=chromium

# 起動済みの環境に対して実行する
PLAYWRIGHT_BASE_URL=http://localhost:8080 npm run test:e2e
```

## BDD Implementation Workflow

### Gherkin → Test → Implementation → E2E の流れ

```
1. Gherkin要件定義
   ↓
2. Feature Test作成（RED）
   ↓
3. 実装（GREEN）
   ↓
4. リファクタリング
   ↓
5. Browser Test作成（E2E確認）
   ↓
6. 全テスト通過を確認
```

### Step 1: Gherkin要件を書く

```gherkin
### REQ-POST-001: 投稿の公開

**Scenario**: 投稿の公開
  Given ログイン済みのユーザーがいる
  And 下書き状態の投稿がある
  When ユーザーが「公開」ボタンをクリックする
  Then 投稿ステータスが「published」になる
  And published_atタイムスタンプが設定される
  And 投稿ページにリダイレクトされる

**Scenario**: タイトルなしの投稿は公開できない
  Given ログイン済みのユーザーがいる
  And タイトルのない下書き投稿がある
  When ユーザーが「公開」ボタンをクリックする
  Then 「タイトルは必須です」エラーが表示される
  And 投稿ステータスは変更されない
```

### Step 2: Feature Test を書く（RED）- scenario() ヘルパー必須

```php
// tests/Feature/Post/PublishPostGwtTest.php
<?php

declare(strict_types=1);

use App\Models\User;
use App\Models\Post;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

/**
 * 投稿公開 - GWT テスト
 *
 * @see docs/specs/post/requirements.md
 */

describe('UC-01: 投稿公開', function () {
    it('Scenario 1.1: 投稿を公開できる', function () {
        scenario('投稿公開フロー')
            ->given('ログイン済みのユーザーがいる', function () {
                return User::factory()->create();
            })
            ->and('下書き状態の投稿がある', function (User $user) {
                $post = Post::factory()
                    ->for($user)
                    ->draft()
                    ->create();

                return ['user' => $user, 'post' => $post];
            })
            ->when('公開リクエストを送信', function (array $context) {
                $this->actingAs($context['user']);

                return $this->post(route('posts.publish', $context['post']));
            })
            ->then('投稿ページにリダイレクトされる', function ($response) {
                $response->assertRedirect();
            })
            ->and('ステータスがpublishedになる', function ($response) {
                $post = Post::latest()->first();
                expect($post->status)->toBe('published');
            })
            ->and('published_atタイムスタンプが設定される', function ($response) {
                $post = Post::latest()->first();
                expect($post->published_at)->not->toBeNull();
            })
            ->run();
    });

    it('Scenario 1.2: タイトルなしでは公開できない', function () {
        scenario('タイトル必須バリデーション')
            ->given('ログイン済みのユーザーがいる', function () {
                return User::factory()->create();
            })
            ->and('タイトルのない下書き投稿がある', function (User $user) {
                $post = Post::factory()
                    ->for($user)
                    ->draft()
                    ->create(['title' => null]);

                return ['user' => $user, 'post' => $post];
            })
            ->when('公開リクエストを送信', function (array $context) {
                $this->actingAs($context['user']);

                return $this->post(route('posts.publish', $context['post']));
            })
            ->then('バリデーションエラーになる', function ($response) {
                $response->assertSessionHasErrors(['title']);
            })
            ->and('投稿ステータスは変更されない', function ($response) {
                $post = Post::latest()->first();
                expect($post->status)->toBe('draft');
            })
            ->run();
    });
});
```

### Step 3: 実装する（GREEN）

```php
// app/Http/Controllers/PostController.php
public function publish(Post $post): RedirectResponse
{
    // バリデーション
    if (empty($post->title)) {
        return back()->withErrors(['title' => 'タイトルは必須です']);
    }

    // 公開処理
    $post->publish();

    return redirect()->route('posts.show', $post);
}

// app/Models/Post.php
public function publish(): void
{
    $this->update([
        'status' => 'published',
        'published_at' => now(),
    ]);
}
```

### Step 4: Browser Test を書く（E2E確認）

```php
// tests/Browser/Post/PublishPostBrowserTest.php
<?php

use App\Models\User;
use App\Models\Post;

it('投稿公開フローが正常に動作する', function () {
    $user = User::factory()->create();
    $post = Post::factory()
        ->for($user)
        ->draft()
        ->create();

    $this->actingAs($user);

    visit(route('posts.edit', $post))
        ->assertSee('Edit Post')
        ->click('Publish')
        ->assertPathIs('/posts/' . $post->slug)
        ->assertSee($post->title)
        ->assertNoJavascriptErrors();
});

it('タイトルなし時にエラーメッセージを表示する', function () {
    $user = User::factory()->create();
    $post = Post::factory()
        ->for($user)
        ->draft()
        ->create(['title' => null]);

    $this->actingAs($user);

    visit(route('posts.edit', $post))
        ->click('Publish')
        ->assertSee('Title is required')
        ->assertPathIs(route('posts.edit', $post));
});
```

### Step 5: 全テスト実行

```bash
# Feature Tests
php artisan test tests/Feature/Post/PublishPostTest.php

# Browser Tests
php artisan test tests/Browser/Post/PublishPostBrowserTest.php

# 全テスト
php artisan test
```

## テスト戦略: Feature vs Browser

| テストタイプ | 用途 | 速度 | カバレッジ |
|-------------|------|------|-----------|
| Feature Test | API/ビジネスロジック | 高速 | ロジック重視 |
| Browser Test | UI/UXフロー | 低速 | ユーザー体験重視 |

**推奨バランス:**
- Feature Tests: 80%（高速、CI向き）
- Browser Tests: 20%（重要フロー、E2E確認）

### Feature Testで十分な場合
- APIエンドポイントの動作確認
- バリデーションルールのテスト
- ビジネスロジックの検証
- データベース状態の確認

### Browser Testが必要な場合
- JavaScriptを含むUIインタラクション
- 複数ページにまたがるフロー
- リアルタイム更新（ポーリング、WebSocket）
- レスポンシブデザインの確認
- ダークモード/テーマ切り替え

## Implementation Report (tasks.md)

**CRITICAL RULE: Always Document Implementation**

After completing each task, add an implementation report:

```markdown
- [x] Task 1.1: Implement post publication

  **Implementation Report:**
  - **Files Changed**:
    - `app/Http/Controllers/PostController.php`
    - `app/Models/Post.php`
  - **Tests Added**:
    - `tests/Feature/Post/PublishPostTest.php`
  - **Key Decisions**: Used model method for publish logic
  - **Notes**: Added published_at timestamp for tracking
```

## Anti-patterns to Avoid

### Test Anti-Patterns
- Writing tests after implementation
- Tests that depend on other tests
- Testing implementation details instead of behavior
- Skipping tests to meet deadlines
- Mocking too much (test behavior, not implementation)

### Documentation Anti-Patterns
- Implementing without requirements
- Vague or incomplete scenarios
- Missing edge cases
- Outdated requirements

## Enforcement Checklist

Before completing any implementation task:

### 要件・ドキュメント
- [ ] Requirement exists in requirements.md (Gherkin format)
- [ ] Gherkin scenario covers happy path and edge cases

### Feature Tests
- [ ] Feature Test written BEFORE implementation
- [ ] Test was RED before GREEN
- [ ] All Feature tests pass (`php artisan test tests/Feature/`)

### Browser Tests（重要フローのみ）
- [ ] Browser Test written for user-facing flows
- [ ] JavaScript errors checked (`assertNoJavascriptErrors`)
- [ ] All Browser tests pass (`php artisan test tests/Browser/`)

### 品質
- [ ] Code refactored if needed
- [ ] No skipped or commented tests
- [ ] Implementation report added to tasks.md

## AI Agent Workflow Integration

1. docs/specs/{feature}/requirements.md のGherkin scenarioを読む。
2. .ai/rules/testing.md の境界と承認条件を確認する。
3. 対象scenarioを1件選びRed → Green → Refactorする。
4. テスト成功後に次のscenarioへ進む。

## Quality Commands

```bash
# Full verification
composer lint      # Pint + PHPStan + Rector dry-run
composer test      # Pest tests
npm run lint       # Biome + ESLint
npm run test:unit  # Vitest tests
npm run types      # TypeScript check
```
