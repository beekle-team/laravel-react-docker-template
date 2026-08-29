---
name: backend-guidelines
description: Enforce Laravel MVC patterns with Concerns and Query Scopes. Controllers stay thin, Models hold logic, and queries read like English sentences.
license: MIT
---

# Laravel MVC + Concerns + Query Scopes

Laravel標準のMVCパターン。Serviceクラスは作らない。クエリはスコープで英語のように読めるように。

**Keywords**: laravel, mvc, concerns, traits, eloquent, query-scopes, model

## 基本原則

1. **Service Layer 禁止**: Serviceクラスは作らない
2. **Fat Model, Skinny Controller**: ロジックはModelに
3. **Concerns**: 共通処理はトレイトで再利用
4. **Query Scopes**: クエリは英語のように読める形で

## クエリスコープ

### 英語のように読めるクエリ

```php
// GOOD: 英語として読める
$posts = Post::query()
    ->published()
    ->forAuthor($author)
    ->withComments()
    ->recentFirst()
    ->get();

// "Get published posts for author with comments, recent first"
```

### スコープ定義

```php
class Post extends Model
{
    // 状態スコープ
    public function scopePublished(Builder $query): Builder
    {
        return $query->whereNotNull('published_at');
    }

    public function scopeDraft(Builder $query): Builder
    {
        return $query->whereNull('published_at');
    }

    // フィルタスコープ
    public function scopeForAuthor(Builder $query, User $author): Builder
    {
        return $query->where('user_id', $author->id);
    }

    public function scopeForCategory(Builder $query, Category $category): Builder
    {
        return $query->where('category_id', $category->id);
    }

    public function scopeOfType(Builder $query, string $type): Builder
    {
        return $query->where('type', $type);
    }

    // Eager Loading スコープ
    public function scopeWithComments(Builder $query): Builder
    {
        return $query->with(['comments', 'comments.user']);
    }

    public function scopeWithAuthor(Builder $query): Builder
    {
        return $query->with('user');
    }

    // 並び替えスコープ
    public function scopeRecentFirst(Builder $query): Builder
    {
        return $query->orderByDesc('created_at');
    }

    public function scopePopular(Builder $query): Builder
    {
        return $query->orderByDesc('view_count');
    }
}
```

### コントローラーでの使用

```php
class PostController extends Controller
{
    public function index()
    {
        $posts = Post::query()
            ->published()
            ->withAuthor()
            ->recentFirst()
            ->paginate(20);

        return Inertia::render('Posts/Index', compact('posts'));
    }

    public function byCategory(Category $category)
    {
        $posts = Post::query()
            ->forCategory($category)
            ->published()
            ->withComments()
            ->recentFirst()
            ->get();

        return Inertia::render('Posts/ByCategory', compact('posts', 'category'));
    }
}
```

## Model構成

### ビジネスロジック

```php
class Post extends Model
{
    use HasSlug;  // Concern

    // スコープ（上記参照）

    // リレーション
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function comments(): HasMany
    {
        return $this->hasMany(Comment::class);
    }

    // ビジネスロジック
    public function publish(): void
    {
        $this->update(['published_at' => now()]);
        $this->user->notify(new PostPublishedNotification($this));
    }

    public function isPublished(): bool
    {
        return $this->published_at !== null;
    }

    public function belongsToUser(User $user): bool
    {
        return $this->user_id === $user->id;
    }
}
```

### Concerns（トレイト）

```php
// app/Models/Concerns/HasSlug.php
trait HasSlug
{
    public static function bootHasSlug(): void
    {
        static::creating(function ($model) {
            $model->slug = Str::slug($model->title);
        });
    }

    public function scopeBySlug(Builder $query, string $slug): Builder
    {
        return $query->where('slug', $slug);
    }

    public function getRouteKeyName(): string
    {
        return 'slug';
    }
}
```

## コントローラー

### シンプルに保つ

```php
class PostController extends Controller
{
    public function show(Post $post)
    {
        $this->authorize('view', $post);

        return Inertia::render('Posts/Show', [
            'post' => $post->load('comments', 'user'),
        ]);
    }

    public function publish(Post $post)
    {
        $this->authorize('update', $post);

        $post->publish();  // Modelのメソッド

        return redirect()->route('posts.show', $post);
    }

    public function store(StorePostRequest $request)
    {
        $post = auth()->user()->posts()->create($request->validated());

        return redirect()->route('posts.show', $post);
    }
}
```

## アンチパターン

### Serviceクラスを作る

```php
// 禁止
class PostService
{
    public function publish($post) { ... }
}
```

### Modelに書く

```php
// Modelのメソッドとして
class Post extends Model
{
    public function publish() { ... }
}
```

### 生のwhere句を並べる

```php
// 読みにくい
$posts = Post::query()
    ->whereNotNull('published_at')
    ->where('user_id', $user->id)
    ->where('type', 'article')
    ->orderByDesc('created_at')
    ->get();
```

### スコープで英語に

```php
// 英語として読める
$posts = Post::query()
    ->published()
    ->forAuthor($user)
    ->ofType('article')
    ->recentFirst()
    ->get();
```

## チェックリスト

- [ ] Serviceクラスを作っていない?
- [ ] クエリはスコープで英語のように読める?
- [ ] ビジネスロジックはModelに?
- [ ] 共通処理はConcernsで再利用?
- [ ] Controllerはシンプル?
- [ ] N+1はスコープでeager loading?

## ファイル構成

```
app/
├── Http/
│   ├── Controllers/       # シンプルに
│   └── Requests/          # バリデーション
├── Models/
│   ├── Concerns/          # 共通トレイト
│   │   ├── HasSlug.php
│   │   └── HasStatus.php
│   ├── Post.php           # スコープ + ロジック
│   ├── User.php
│   └── ...
├── Jobs/                  # 非同期処理
└── (Servicesは作らない)
```

## スコープ命名規則

| プレフィックス | 用途 | 例 |
|--------------|------|-----|
| (なし) | 状態フィルタ | `published()`, `draft()`, `active()` |
| `for` | 所有者フィルタ | `forUser()`, `forAuthor()` |
| `of` / `ofType` | 種別フィルタ | `ofType()`, `ofStatus()` |
| `with` | Eager Loading | `withComments()`, `withAuthor()` |
| `by` / `orderBy` | 並び替え | `byPopularity()`, `recentFirst()` |
| `where` | 条件（最後の手段） | `whereViewsAbove()` |

## 主要ライブラリ

### Backend
| パッケージ | 用途 |
|-----------|------|
| `spatie/laravel-data` | DTOクラス、Inertia連携 |
| `spatie/laravel-typescript-transformer` | PHP→TypeScript型生成 |
| `tightenco/ziggy` | フロントエンドへのルート共有 |

### Frontend
| パッケージ | 用途 |
|-----------|------|
| `@inertiajs/react` | SPA連携 |
| `@radix-ui/*` | アクセシブルUIプリミティブ |
| `laravel-precognition-react` | バリデーション先行実行 |

## Laravel Data + TypeScript 型同期

### 開発サイクル

```
1. app/Data/*.php を作成・変更
2. php artisan typescript:transform を実行
3. resources/types/generated.d.ts が更新される
4. フロントエンドで型が自動補完される
```

### Data クラスの作成

```php
// app/Data/UserData.php
namespace App\Data;

use Spatie\LaravelData\Data;
use Spatie\LaravelData\Attributes\MapName;
use Spatie\LaravelData\Mappers\SnakeCaseMapper;
use Spatie\TypeScriptTransformer\Attributes\TypeScript;

#[TypeScript]                       // TypeScript に変換
#[MapName(SnakeCaseMapper::class)]  // snake_case → camelCase 変換
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

### 生成される TypeScript 型

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
```

### フロントエンドでの使用

```tsx
// resources/js/pages/users/index.tsx
import { PageProps } from '@/types';

interface Props extends PageProps {
    users: App.Data.UserData[];  // 自動補完が効く
}

export default function UsersIndex({ users }: Props) {
    return (
        <ul>
            {users.map(user => (
                <li key={user.id}>{user.name}</li>
            ))}
        </ul>
    );
}
```

### Enum も自動変換

```php
// app/Enums/PostStatus.php
enum PostStatus: string
{
    case Draft = 'draft';
    case Published = 'published';
    case Archived = 'archived';
}
```

```typescript
// 生成される型
declare namespace App.Enums {
  export type PostStatus = 'draft' | 'published' | 'archived';
}
```

### 重要: Data クラス変更時の手順

```bash
# 1. Data クラスを編集
# 2. TypeScript 型を再生成
php artisan typescript:transform

# 3. フロントエンドの型エラーを確認
npm run types
```

## Inertia レスポンスパターン

### Controller → Data → TypeScript

```php
// Controller
public function show(Post $post)
{
    return Inertia::render('Posts/Show', [
        'post' => PostData::from($post),  // Data クラス
        'comments' => CommentData::collect($post->comments),
    ]);
}
```

```tsx
// React コンポーネント
interface Props extends PageProps {
    post: App.Data.PostData;  // 型安全
    comments: App.Data.CommentData[];
}
```

## 開発コマンド一覧

### 型生成・同期
```bash
# TypeScript 型を再生成（Data クラス変更時）
php artisan typescript:transform

# IDE Helper 更新（モデル変更時）
php artisan ide-helper:models -W
```

### コード品質
```bash
# PHP
composer lint          # Pint + PHPStan + Rector dry-run
composer pint          # フォーマット
composer stan          # 静的解析
composer rector        # Rector dry-run
composer test          # Pest テスト

# TypeScript
npm run lint:js        # Biome lint
npm run types          # 型チェック
npm run test:unit      # Vitest
```

### 開発サーバー
```bash
# 全サービス起動（推奨）
composer dev
# → Laravel + Queue + Pail + Vite を同時起動

# フロントエンドのみ
npm run dev
```

### キャッシュ
```bash
# 設定キャッシュクリア
php artisan config:clear
php artisan cache:clear

# ルートキャッシュ
php artisan route:clear
```

## チェックリスト（追加）

- [ ] 新しい Data クラスに `#[TypeScript]` 属性を付けた?
- [ ] `php artisan typescript:transform` を実行した?
- [ ] フロントエンドの型エラーを確認した?
- [ ] Enum も TypeScript に変換される?
