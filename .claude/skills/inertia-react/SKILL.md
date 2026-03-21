---
name: inertia-react
description: Inertia.js v2 + React開発のベストプラクティス。ページ作成、フォーム処理、ナビゲーション、データ取得、ポーリング、プリフェッチ、遅延読み込み、Laravel Precognition（リアルタイムバリデーション）などInertia v2の全機能を網羅。Laravel + React SPAを構築する際に使用。
license: MIT
---

# Inertia.js v2 + React Development Guide

このスキルはInertia.js v2とReactを使用したモダンなSPA開発のガイドラインを提供します。
**Laravel Data**を使用したDTO作成と**TypeScript型の自動生成**についても解説します。

**Keywords**: inertia, react, spa, forms, useForm, router, Link, deferred, prefetch, polling, infinite-scroll, laravel-data, spatie, typescript-transformer, dto, type-generation

## プロジェクトコンテキスト

**Stack**: Laravel 13 + Inertia.js v2 + React 18 + TypeScript
**Data Layer**: Spatie Laravel Data v4 + TypeScript Transformer v2
**Routing**: Ziggy (`route()` helper)
**Styling**: Tailwind CSS v4

---

## Laravel Data + TypeScript型生成

### 概要

このプロジェクトでは `spatie/laravel-data` と `spatie/laravel-typescript-transformer` を使用して、PHP側のData Transfer Objects（DTO）からTypeScript型を自動生成します。

```
PHP Data Class → TypeScript Type → React Component
     ↓                ↓                  ↓
CompanyData.php → generated.d.ts → usePage<Props>()
```

### 1. Data クラスの作成

```php
// app/Data/UserData.php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Attributes\MapName;
use Spatie\LaravelData\Data;
use Spatie\LaravelData\Mappers\SnakeCaseMapper;
use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]  // ← TypeScript型を生成するために必須
#[MapName(SnakeCaseMapper::class)]  // ← snake_case → camelCase変換
class UserData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public string $email,
        public ?string $avatar,
        public ?string $emailVerifiedAt,
        public string $createdAt,
        public string $updatedAt,
    ) {}
}
```

### 2. ネストしたData構造

```php
// app/Data/AddressData.php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]
class AddressData extends Data
{
    public function __construct(
        public string $street,
        public string $city,
        public string $postalCode,
        public string $country,
    ) {}
}
```

```php
// app/Data/CompanyData.php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]
class CompanyData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public AddressData $address,  // ネストしたData
        public ?string $website,      // nullable
    ) {}
}
```

### 3. TypeScript型の生成

```bash
# 型を生成
php artisan typescript:transform

# 出力先: resources/types/generated.d.ts
```

**生成される型の例:**

```typescript
// resources/types/generated.d.ts
declare namespace App.Data {
  export type UserData = {
    id: number;
    name: string;
    email: string;
    avatar: string | null;
    emailVerifiedAt: string | null;
    createdAt: string;
    updatedAt: string;
  };
}

declare namespace App.Data {
  export type AddressData = {
    street: string;
    city: string;
    postalCode: string;
    country: string;
  };
}
```

### 4. Controllerでの使用

```php
// app/Http/Controllers/UserController.php
use App\Data\UserData;
use Inertia\Inertia;
use Inertia\Response;

class UserController extends Controller
{
    public function index(): Response
    {
        return Inertia::render('Users/Index', [
            'users' => UserData::collect(
                User::query()->latest()->paginate(15)
            ),
        ]);
    }

    public function show(User $user): Response
    {
        return Inertia::render('Users/Show', [
            'user' => UserData::from($user),
        ]);
    }
}
```

### 5. React側での型利用

```tsx
// resources/js/pages/Users/Index.tsx
import { Head } from '@inertiajs/react';
import AuthenticatedLayout from '@/layouts/AuthenticatedLayout';
import { PageProps } from '@/types';

// 生成された型を使用
interface Props extends PageProps {
  users: {
    data: App.Data.UserData[];
    links: PaginationLinks;
    meta: PaginationMeta;
  };
}

export default function UsersIndex({ users }: Props) {
  return (
    <AuthenticatedLayout>
      <Head title="Users" />
      {users.data.map(user => (
        <div key={user.id}>
          <span>{user.name}</span>
          <span>{user.email}</span>
        </div>
      ))}
    </AuthenticatedLayout>
  );
}
```

### 6. 配列とコレクション

```php
// 配列プロパティ
#[TypeScript]
class TeamData extends Data
{
    /**
     * @param UserData[] $members
     */
    public function __construct(
        public int $id,
        public string $name,
        /** @var UserData[] */
        public array $members,
    ) {}
}
```

```php
// DataCollectionを使用
use Spatie\LaravelData\DataCollection;

#[TypeScript]
class TeamData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        /** @var DataCollection<UserData> */
        public DataCollection $members,
    ) {}
}
```

### 7. Enumの活用

```php
// app/Enums/AssessmentStatus.php
<?php

namespace App\Enums;

use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]
enum AssessmentStatus: string
{
    case Pending = 'pending';
    case InProgress = 'in_progress';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
```

```php
// Data内でEnumを使用
#[TypeScript]
class AssessmentData extends Data
{
    public function __construct(
        public int $id,
        public AssessmentStatus $status,  // ← Enum型
    ) {}
}
```

**生成されるTypeScript:**

```typescript
declare namespace App.Enums {
  export type AssessmentStatus = 'pending' | 'in_progress' | 'completed' | 'cancelled';
}
```

### 8. 設定ファイル

```php
// config/typescript-transformer.php
return [
    'auto_discover_types' => [
        app_path(),
    ],

    'collectors' => [
        Spatie\TypeScriptTransformer\Collectors\DefaultCollector::class,
        Spatie\TypeScriptTransformer\Collectors\EnumCollector::class,
    ],

    'transformers' => [
        Spatie\LaravelTypeScriptTransformer\Transformers\SpatieStateTransformer::class,
        Spatie\TypeScriptTransformer\Transformers\EnumTransformer::class,
        Spatie\LaravelTypeScriptTransformer\Transformers\DtoTransformer::class,
    ],

    'default_type_replacements' => [
        DateTime::class => 'string',
        DateTimeImmutable::class => 'string',
        Carbon\Carbon::class => 'string',
    ],

    'output_file' => resource_path('types/generated.d.ts'),
];
```

### 9. Model から Data への変換

```php
// 基本的な変換
$userData = UserData::from($user);

// コレクションの変換
$usersData = UserData::collect($users);

// ページネーションの維持
$paginatedData = UserData::collect(
    User::query()->paginate(15)
);
// → LengthAwarePaginator のまま、data 部分が UserData に変換される

// カスタムマッピング
#[TypeScript]
class UserData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public string $email,
        public ?string $avatarUrl,  // ← カスタム名
    ) {}

    public static function fromModel(User $user): self
    {
        return new self(
            id: $user->id,
            name: $user->name,
            email: $user->email,
            avatarUrl: $user->avatar?->url,  // ← リレーションから取得
        );
    }
}

// Lazy Loading（パフォーマンス最適化）
use Spatie\LaravelData\Lazy;

#[TypeScript]
class UserData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public Lazy|CompanyData $company,  // ← 必要時のみ読み込み
    ) {}

    public static function fromModel(User $user): self
    {
        return new self(
            id: $user->id,
            name: $user->name,
            company: Lazy::whenLoaded('company', $user, fn () => CompanyData::from($user->company)),
        );
    }
}
```

### 10. Validation（バリデーション）

```php
// DataクラスでValidationルールを定義
use Spatie\LaravelData\Attributes\Validation\Email;
use Spatie\LaravelData\Attributes\Validation\Max;
use Spatie\LaravelData\Attributes\Validation\Required;

#[TypeScript]
class CreateUserData extends Data
{
    public function __construct(
        #[Required, Max(255)]
        public string $name,

        #[Required, Email, Max(255)]
        public string $email,

        #[Required, Max(255)]
        public string $password,
    ) {}
}

// Controller で使用
public function store(CreateUserData $data): RedirectResponse
{
    // $data は自動的にバリデーション済み
    User::create($data->toArray());

    return redirect()->route('users.index');
}
```

### Laravel Data ベストプラクティス

#### DO（推奨）

- **すべてのInertia propsにDataクラスを使用**
- **`#[TypeScript]` 属性を忘れずに付与**
- **`#[MapName(SnakeCaseMapper::class)]` でフロントエンドに適した命名規則**
- **PHPDocで配列の型を明示**（`@var UserData[]`）
- **日付はstringで定義**（Carbon → TypeScript string）
- **Enumを活用して型安全性を向上**

#### DON'T（非推奨）

- **生の配列をInertiaに渡さない**（Dataクラスを使用）
- **`#[TypeScript]` 属性を忘れない**（型が生成されない）
- **複雑なオブジェクトをmixed/anyで定義しない**
- **手動でTypeScript型を書かない**（自動生成を活用）

### ワークフロー

```
1. Data クラスを作成/編集
   ↓
2. php artisan typescript:transform
   ↓
3. resources/types/generated.d.ts が更新される
   ↓
4. React コンポーネントで App.Data.* 型を使用
```

**npm script として登録（推奨）:**

```json
{
  "scripts": {
    "types": "php artisan typescript:transform"
  }
}
```

---

## コアコンセプト

### 1. Inertiaページの基本構造

```tsx
// resources/js/pages/Users/Index.tsx
import { Head } from '@inertiajs/react';
import AuthenticatedLayout from '@/layouts/AuthenticatedLayout';
import { PageProps } from '@/types';

interface User {
  id: number;
  name: string;
  email: string;
}

interface Props extends PageProps {
  users: User[];
}

export default function UsersIndex({ users }: Props) {
  return (
    <AuthenticatedLayout>
      <Head title="Users" />

      <div className="py-12">
        {users.map(user => (
          <div key={user.id}>{user.name}</div>
        ))}
      </div>
    </AuthenticatedLayout>
  );
}
```

### 2. Laravel側のレスポンス

```php
// app/Http/Controllers/UserController.php
use Inertia\Inertia;
use Inertia\Response;

public function index(): Response
{
    return Inertia::render('Users/Index', [
        'users' => User::query()
            ->select(['id', 'name', 'email'])
            ->paginate(15),
    ]);
}
```

## ナビゲーション

### Link コンポーネント

```tsx
import { Link } from '@inertiajs/react';

// 基本的なリンク
<Link href="/users">Users</Link>

// Ziggy route()を使用（推奨）
<Link href={route('users.show', { user: user.id })}>
  {user.name}
</Link>

// メソッド指定
<Link href={route('logout')} method="post" as="button">
  Logout
</Link>

// プリザーブスクロール
<Link href="/users" preserveScroll>Users</Link>

// 状態保持
<Link href="/users" preserveState>Users</Link>
```

### router.visit()

```tsx
import { router } from '@inertiajs/react';

// 基本的な遷移
router.visit('/users');

// オプション付き
router.visit(route('users.show', { user: 1 }), {
  method: 'get',
  preserveScroll: true,
  preserveState: true,
  only: ['users'], // 特定のpropsのみ更新
  onSuccess: () => console.log('Success!'),
  onError: (errors) => console.error(errors),
});

// POST/PUT/DELETE
router.post('/users', { name: 'John' });
router.put(route('users.update', { user: 1 }), { name: 'Jane' });
router.delete(route('users.destroy', { user: 1 }));
```

## フォーム処理

### useForm フック（推奨）

```tsx
import { useForm } from '@inertiajs/react';

interface FormData {
  name: string;
  email: string;
  role: 'admin' | 'user';
}

export default function CreateUser() {
  const { data, setData, post, processing, errors, reset, clearErrors } = useForm<FormData>({
    name: '',
    email: '',
    role: 'user',
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    post(route('users.store'), {
      onSuccess: () => reset(),
      preserveScroll: true,
    });
  }

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input
          type="text"
          value={data.name}
          onChange={e => setData('name', e.target.value)}
          className={errors.name ? 'border-red-500' : ''}
        />
        {errors.name && <p className="text-red-500 text-sm">{errors.name}</p>}
      </div>

      <div>
        <input
          type="email"
          value={data.email}
          onChange={e => setData('email', e.target.value)}
        />
        {errors.email && <p className="text-red-500 text-sm">{errors.email}</p>}
      </div>

      <div>
        <select
          value={data.role}
          onChange={e => setData('role', e.target.value as 'admin' | 'user')}
        >
          <option value="user">User</option>
          <option value="admin">Admin</option>
        </select>
      </div>

      <button type="submit" disabled={processing}>
        {processing ? 'Creating...' : 'Create User'}
      </button>
    </form>
  );
}
```

### ファイルアップロード

```tsx
const { data, setData, post, progress } = useForm({
  name: '',
  avatar: null as File | null,
});

function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
  if (e.target.files?.[0]) {
    setData('avatar', e.target.files[0]);
  }
}

function handleSubmit(e: React.FormEvent) {
  e.preventDefault();
  post(route('users.store'), {
    forceFormData: true, // multipart/form-data を強制
  });
}

// プログレス表示
{progress && (
  <progress value={progress.percentage} max="100">
    {progress.percentage}%
  </progress>
)}
```

### Laravel Precognition（リアルタイムバリデーション）

Laravel Precognition を使用すると、サーバーサイドのバリデーションルールをフロントエンドでリアルタイムに実行できます。

#### セットアップ

```bash
# Laravel側
composer require laravel/precognition

# React側
npm install laravel-precognition-react
```

#### Laravel側の設定

```php
// routes/web.php
use Illuminate\Foundation\Http\Middleware\HandlePrecognitiveRequests;

Route::post('/users', [UserController::class, 'store'])
    ->middleware([HandlePrecognitiveRequests::class]);
```

```php
// app/Http/Controllers/UserController.php
use App\Http\Requests\StoreUserRequest;

class UserController extends Controller
{
    public function store(StoreUserRequest $request)
    {
        // Precognitionリクエストの場合、ここには到達しない
        // バリデーション通過後のみ実行される
        User::create($request->validated());

        return redirect()->route('users.index');
    }
}
```

```php
// app/Http/Requests/StoreUserRequest.php
class StoreUserRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:users,email'],
            'password' => ['required', 'min:8', 'confirmed'],
        ];
    }
}
```

#### React側の実装

```tsx
import { useForm } from 'laravel-precognition-react-inertia';

interface FormData {
  name: string;
  email: string;
  password: string;
  password_confirmation: string;
}

export default function CreateUser() {
  const form = useForm<FormData>('post', route('users.store'), {
    name: '',
    email: '',
    password: '',
    password_confirmation: '',
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    form.submit({
      onSuccess: () => form.reset(),
      preserveScroll: true,
    });
  }

  return (
    <form onSubmit={handleSubmit}>
      <div>
        <input
          type="text"
          value={form.data.name}
          onChange={e => form.setData('name', e.target.value)}
          onBlur={() => form.validate('name')}  // フォーカス外れたらバリデーション
        />
        {form.invalid('name') && (
          <p className="text-red-500 text-sm">{form.errors.name}</p>
        )}
      </div>

      <div>
        <input
          type="email"
          value={form.data.email}
          onChange={e => form.setData('email', e.target.value)}
          onBlur={() => form.validate('email')}  // unique チェックもリアルタイム
        />
        {form.invalid('email') && (
          <p className="text-red-500 text-sm">{form.errors.email}</p>
        )}
        {form.validating && <span className="text-gray-400">確認中...</span>}
      </div>

      <div>
        <input
          type="password"
          value={form.data.password}
          onChange={e => form.setData('password', e.target.value)}
          onBlur={() => form.validate('password')}
        />
        {form.invalid('password') && (
          <p className="text-red-500 text-sm">{form.errors.password}</p>
        )}
      </div>

      <div>
        <input
          type="password"
          value={form.data.password_confirmation}
          onChange={e => form.setData('password_confirmation', e.target.value)}
          onBlur={() => form.validate('password')}  // confirmed ルール用
        />
      </div>

      <button
        type="submit"
        disabled={form.processing || form.hasErrors}
      >
        {form.processing ? 'Creating...' : 'Create User'}
      </button>
    </form>
  );
}
```

#### Precognition API

```tsx
const form = useForm('post', route('users.store'), initialData);

// バリデーション
form.validate('email');              // 単一フィールド
form.validate(['email', 'name']);    // 複数フィールド
form.validateFiles();                // ファイルのみ

// 状態チェック
form.valid('email');                 // バリデーション成功?
form.invalid('email');               // バリデーション失敗?
form.validating;                     // バリデーション中?
form.hasErrors;                      // エラーあり?

// エラー
form.errors.email;                   // エラーメッセージ
form.setErrors({ email: 'Error' }); // 手動設定
form.forgetError('email');          // エラークリア
form.clearErrors();                  // 全クリア

// 送信
form.submit();                       // フォーム送信
form.submit({ onSuccess, onError }); // コールバック付き

// リセット
form.reset();                        // 全リセット
form.reset('email');                 // 特定フィールド
```

#### デバウンス設定

```tsx
const form = useForm('post', route('users.store'), initialData);

// 入力中にリアルタイムバリデーション（デバウンス付き）
<input
  value={form.data.email}
  onChange={e => {
    form.setData('email', e.target.value);
    form.validate('email');  // 自動的にデバウンスされる（デフォルト: 1500ms）
  }}
/>
```

```tsx
// デバウンス時間をカスタマイズ
form.setValidationTimeout(500);  // 500ms に変更
```

#### Precognition vs Inertia useForm

| 機能 | Inertia useForm | Precognition |
|------|----------------|--------------|
| 基本フォーム処理 | 対応 | 対応 |
| リアルタイムバリデーション | 非対応 | 対応 |
| uniqueルールのリアルタイムチェック | 非対応 | 対応 |
| サーバーサイドルール活用 | 送信時のみ | リアルタイム |
| デバウンス | 非対応 | 対応 |

**使い分け:**
- **シンプルなフォーム** → Inertia `useForm`
- **リアルタイムバリデーションが必要** → Precognition
- **uniqueチェックが必要** → Precognition

## Inertia v2 新機能

### 1. Deferred Props（遅延読み込み）

```php
// Laravel側
use Inertia\Inertia;

public function show(User $user): Response
{
    return Inertia::render('Users/Show', [
        'user' => $user,
        // 遅延読み込み - ページ表示後に非同期で取得
        'activities' => Inertia::defer(fn () => $user->activities()->latest()->take(10)->get()),
        'statistics' => Inertia::defer(fn () => $this->calculateStats($user)),
    ]);
}
```

```tsx
// React側 - スケルトン表示
import { Deferred } from '@inertiajs/react';

interface Props {
  user: User;
  activities?: Activity[];
  statistics?: Statistics;
}

export default function UserShow({ user, activities, statistics }: Props) {
  return (
    <div>
      <h1>{user.name}</h1>

      {/* 遅延データ用スケルトン */}
      <Deferred data="activities" fallback={<ActivitiesSkeleton />}>
        <ActivityList activities={activities!} />
      </Deferred>

      <Deferred data="statistics" fallback={<StatsSkeleton />}>
        <StatsCard statistics={statistics!} />
      </Deferred>
    </div>
  );
}

// スケルトンコンポーネント
function ActivitiesSkeleton() {
  return (
    <div className="space-y-4 animate-pulse">
      {[...Array(5)].map((_, i) => (
        <div key={i} className="h-16 bg-neutral-200 dark:bg-neutral-700 rounded-lg" />
      ))}
    </div>
  );
}
```

### 2. Polling（定期更新）

```tsx
import { usePoll } from '@inertiajs/react';

export default function Dashboard({ notifications }: Props) {
  // 30秒ごとにnotificationsを更新
  usePoll(30000, {
    only: ['notifications'],
    keepAlive: true, // タブがバックグラウンドでも継続
  });

  return (
    <div>
      <NotificationList notifications={notifications} />
    </div>
  );
}
```

```tsx
// 条件付きポーリング
const { start, stop } = usePoll(5000, {
  only: ['status'],
  autoStart: false, // 手動開始
});

// 処理中のみポーリング
useEffect(() => {
  if (isProcessing) {
    start();
  } else {
    stop();
  }
}, [isProcessing]);
```

### 3. Prefetching（プリフェッチ）

```tsx
import { Link } from '@inertiajs/react';

// ホバー時にプリフェッチ
<Link href={route('users.show', { user })} prefetch>
  {user.name}
</Link>

// プリフェッチオプション
<Link
  href={route('users.show', { user })}
  prefetch="hover"      // hover | mount | click
  cacheFor={30000}      // キャッシュ時間（ms）
>
  {user.name}
</Link>
```

```tsx
// プログラマティック プリフェッチ
import { router } from '@inertiajs/react';

router.prefetch(route('users.show', { user: 1 }), {
  cacheFor: 60000,
});
```

### 4. Infinite Scroll（無限スクロール）

```php
// Laravel側 - マージ可能なprops
use Inertia\Inertia;

public function index(Request $request): Response
{
    $users = User::query()
        ->latest()
        ->cursorPaginate(15);

    return Inertia::render('Users/Index', [
        'users' => Inertia::merge($users), // マージを有効化
    ]);
}
```

```tsx
// React側
import { WhenVisible } from '@inertiajs/react';
import { router } from '@inertiajs/react';

interface Props {
  users: {
    data: User[];
    next_cursor: string | null;
    next_page_url: string | null;
  };
}

export default function UsersIndex({ users }: Props) {
  function loadMore() {
    if (users.next_page_url) {
      router.get(users.next_page_url, {}, {
        preserveState: true,
        preserveScroll: true,
        only: ['users'],
      });
    }
  }

  return (
    <div>
      {users.data.map(user => (
        <UserCard key={user.id} user={user} />
      ))}

      {/* 表示されたら自動で次を読み込み */}
      {users.next_page_url && (
        <WhenVisible once fallback={<LoadingSpinner />} onVisible={loadMore}>
          <div className="h-20" /> {/* トリガー要素 */}
        </WhenVisible>
      )}
    </div>
  );
}
```

### 5. History State（履歴状態）

```tsx
import { router, usePage } from '@inertiajs/react';

// 状態を履歴に保存
function handleFilterChange(filter: string) {
  router.get(
    route('users.index'),
    { filter },
    {
      preserveState: true,
      replace: true, // 履歴を置き換え（戻るボタンで前の状態に戻らない）
    }
  );
}

// 現在のページ情報を取得
const { url, props } = usePage();
```

## 共有データ

### グローバルに共有されるデータ

```php
// app/Http/Middleware/HandleInertiaRequests.php
public function share(Request $request): array
{
    return [
        ...parent::share($request),
        'auth' => [
            'user' => $request->user(),
        ],
        'flash' => [
            'success' => fn () => $request->session()->get('success'),
            'error' => fn () => $request->session()->get('error'),
        ],
        'ziggy' => fn () => [
            ...(new Ziggy)->toArray(),
            'location' => $request->url(),
        ],
    ];
}
```

```tsx
// React側で使用
import { usePage } from '@inertiajs/react';
import { PageProps } from '@/types';

export default function Component() {
  const { auth, flash } = usePage<PageProps>().props;

  return (
    <div>
      {auth.user && <p>Welcome, {auth.user.name}!</p>}
      {flash.success && <Alert type="success">{flash.success}</Alert>}
    </div>
  );
}
```

## TypeScript型定義

### types/index.d.ts

```typescript
// resources/js/types/index.d.ts
import { Config } from 'ziggy-js';

export interface User {
  id: number;
  name: string;
  email: string;
  email_verified_at?: string;
  created_at: string;
  updated_at: string;
}

export interface PageProps<T extends Record<string, unknown> = Record<string, unknown>> {
  auth: {
    user: User | null;
  };
  flash: {
    success?: string;
    error?: string;
  };
  ziggy: Config & { location: string };
  [key: string]: unknown;
}

// ページ固有のpropsを拡張
export interface UsersIndexProps extends PageProps {
  users: {
    data: User[];
    links: PaginationLinks;
    meta: PaginationMeta;
  };
}
```

## ベストプラクティス

### DO（推奨）

- `route()` ヘルパーでルート生成（ハードコードURL禁止）
- `useForm` でフォーム状態管理
- `Deferred` で重いデータを遅延読み込み
- TypeScriptで型安全性を確保
- `only` オプションで必要なpropsのみ更新
- `preserveScroll` でスクロール位置を維持
- スケルトンUIで遅延読み込み中を表示

### DON'T（非推奨）

- `<a href="">` を使わない（`<Link>` を使用）
- `window.location` を使わない（`router` を使用）
- `fetch`/`axios` を直接使わない（Inertia経由で）
- グローバルステートを過度に使用しない
- 巨大なpropsを一度に送らない（ページネーション/遅延読み込み）

## エラーハンドリング

### バリデーションエラー

```tsx
const { errors, setError, clearErrors } = useForm({ ... });

// 手動でエラーを設定
setError('email', 'This email is already taken.');

// 特定のエラーをクリア
clearErrors('email');

// 全エラーをクリア
clearErrors();
```

### グローバルエラーハンドリング

```tsx
// resources/js/app.tsx
import { router } from '@inertiajs/react';

router.on('error', (event) => {
  // 500エラーなどをグローバルで処理
  console.error('Inertia error:', event);
});

router.on('invalid', (event) => {
  // 無効なレスポンス（HTMLが返ってきた等）
  event.preventDefault();
  // カスタム処理
});
```

## パフォーマンス最適化

### 1. Partial Reloads

```tsx
// 特定のpropsのみ更新
router.reload({ only: ['users'] });

// 特定のpropsを除外
router.reload({ except: ['flash'] });
```

### 2. レイジーコンポーネント

```tsx
import { lazy, Suspense } from 'react';

const HeavyChart = lazy(() => import('@/components/HeavyChart'));

export default function Dashboard({ data }: Props) {
  return (
    <Suspense fallback={<ChartSkeleton />}>
      <HeavyChart data={data} />
    </Suspense>
  );
}
```

### 3. メモ化

```tsx
import { memo, useMemo } from 'react';

// コンポーネントのメモ化
const UserCard = memo(function UserCard({ user }: { user: User }) {
  return <div>{user.name}</div>;
});

// 計算結果のメモ化
const sortedUsers = useMemo(
  () => users.sort((a, b) => a.name.localeCompare(b.name)),
  [users]
);
```

## ディレクトリ構造

```
resources/js/
├── pages/              # Inertiaページ（自動ルーティング）
│   ├── Auth/
│   │   ├── Login.tsx
│   │   └── Register.tsx
│   ├── Dashboard.tsx
│   └── Users/
│       ├── Index.tsx
│       ├── Show.tsx
│       └── Edit.tsx
├── components/         # 再利用可能なコンポーネント
│   ├── ui/            # プリミティブ
│   └── forms/         # フォームコンポーネント
├── layouts/           # レイアウトコンポーネント
│   ├── AuthenticatedLayout.tsx
│   └── GuestLayout.tsx
├── hooks/             # カスタムフック
├── types/             # TypeScript型定義
│   └── index.d.ts
└── lib/               # ユーティリティ
    └── utils.ts
```

## 品質チェックリスト

### ページ/コンポーネント作成時

- [ ] TypeScript型が完全に定義されている
- [ ] `route()` ヘルパーでルート生成
- [ ] `<Link>` / `router` でナビゲーション
- [ ] フォームは `useForm` で管理（リアルタイムバリデーションには Precognition）
- [ ] 遅延データには `Deferred` + スケルトン
- [ ] エラー表示が適切
- [ ] `preserveScroll` / `preserveState` を適切に使用
- [ ] レイアウトコンポーネントを使用

### Precognition 使用時

- [ ] ルートに `HandlePrecognitiveRequests` ミドルウェアを設定
- [ ] `laravel-precognition-react-inertia` からインポート
- [ ] `onBlur` で `form.validate()` を呼び出し
- [ ] `form.invalid()` / `form.valid()` でエラー状態を表示
- [ ] `form.validating` でローディング状態を表示
- [ ] ボタンに `disabled={form.processing || form.hasErrors}` を設定

### Laravel Data + 型生成時

- [ ] Dataクラスに `#[TypeScript]` 属性が付与されている
- [ ] 必要に応じて `#[MapName(SnakeCaseMapper::class)]` を使用
- [ ] ネストしたDataも `#[TypeScript]` 属性を持つ
- [ ] Enumには `#[TypeScript]` 属性を付与
- [ ] `php artisan typescript:transform` で型を再生成
- [ ] 生成された型（`App.Data.*`）をReactで使用
- [ ] 配列には PHPDoc で型を明示（`@var UserData[]`）
- [ ] Controllerでは `DataClass::from()` / `DataClass::collect()` を使用
