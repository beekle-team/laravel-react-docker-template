# DRY Check - 重複コード検出とリファクタリング

コード作成・編集時に重複パターンを検出し、DRY（Don't Repeat Yourself）原則に基づいたリファクタリングを提案するスキル。

**アーキテクチャ**: Fat Model + Concerns（Service/Actionパターンは使用しない）

**Keywords**: dry, duplicate, refactor, fat-model, trait, concern, hook, utility, query-scope

## 検出トリガー

以下のパターンを検出した場合、自動的にリファクタリングを提案:

1. **3行以上の同一/類似コードブロック**が2箇所以上
2. **同じロジック**が異なるファイルに存在
3. **コピペパターン**（変数名のみ異なる同一構造）
4. **類似バリデーションルール**の繰り返し
5. **同一クエリパターン**の複数箇所での使用

## 重複タイプと解決策

### Type 1: 完全重複（Exact Clones）

同一コードが複数箇所に存在

```php
// BAD: 同じコードが複数箇所に
// UserController.php
$user->notify(new WelcomeNotification($user));
Log::info('User notified', ['user_id' => $user->id]);

// AdminController.php
$user->notify(new WelcomeNotification($user));
Log::info('User notified', ['user_id' => $user->id]);
```

```php
// GOOD: Modelメソッドに抽出
// app/Models/User.php
class User extends Model
{
    public function sendWelcomeNotification(): void
    {
        $this->notify(new WelcomeNotification($this));
        Log::info('User notified', ['user_id' => $this->id]);
    }
}

// Controller
$user->sendWelcomeNotification();
```

### Type 2: パラメータ化重複（Parameterized Clones）

変数名・値のみ異なる同一構造

```tsx
// BAD: 同じ構造、異なる値
const [name, setName] = useState('');
const [nameError, setNameError] = useState('');
const validateName = () => { ... };

const [email, setEmail] = useState('');
const [emailError, setEmailError] = useState('');
const validateEmail = () => { ... };
```

```tsx
// GOOD: カスタムフックに抽出
function useFormField(initialValue: string, validator: (v: string) => string | null) {
  const [value, setValue] = useState(initialValue);
  const [error, setError] = useState<string | null>(null);

  const validate = useCallback(() => {
    const err = validator(value);
    setError(err);
    return !err;
  }, [value, validator]);

  return { value, setValue, error, validate };
}

// 使用
const name = useFormField('', validateRequired);
const email = useFormField('', validateEmail);
```

### Type 3: 構造的重複（Structural Clones）

異なる処理だが同一パターン/構造

```php
// BAD: 同じパターンの繰り返し
public function getActiveUsers(): Collection
{
    return User::query()
        ->where('status', 'active')
        ->orderBy('created_at', 'desc')
        ->get();
}

public function getActiveProducts(): Collection
{
    return Product::query()
        ->where('status', 'active')
        ->orderBy('created_at', 'desc')
        ->get();
}
```

```php
// GOOD: Query Scopeに抽出
// app/Models/Concerns/HasActiveScope.php
trait HasActiveScope
{
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', 'active');
    }

    public function scopeLatestFirst(Builder $query): Builder
    {
        return $query->orderBy('created_at', 'desc');
    }
}

// 使用
User::active()->latestFirst()->get();
Product::active()->latestFirst()->get();
```

## PHP/Laravel リファクタリングパターン

このプロジェクトでは **Fat Model + Concerns** アプローチを採用。
ビジネスロジックはModelに集約し、共通機能はConcerns（Traits）で共有する。

### 1. Model メソッド（Fat Model）

ビジネスロジックはModelに集約

```php
// app/Models/Assessment.php
class Assessment extends Model
{
    // ビジネスロジックをModelに
    public function calculateScores(): array
    {
        return [
            'domains' => $this->calculateDomainScores(),
            'facets' => $this->calculateFacetScores(),
            'overall' => $this->calculateOverallScore(),
        ];
    }

    public function complete(): void
    {
        $this->update(['status' => 'completed', 'completed_at' => now()]);
        $this->candidate->notify(new AssessmentCompletedNotification($this));
    }

    private function calculateDomainScores(): array
    {
        return $this->responses
            ->groupBy('domain')
            ->map(fn ($responses) => $responses->avg('score'))
            ->toArray();
    }
}

// Controller は薄く保つ
public function complete(Assessment $assessment): RedirectResponse
{
    $assessment->complete();
    return redirect()->route('assessments.show', $assessment);
}
```

**使用基準**:
- そのModelに関連するビジネスロジック
- Modelの状態を変更する処理
- リレーションを使った計算・集計

### 2. Traits/Concerns

モデル間で共有するスコープ・メソッド

```php
// app/Models/Concerns/HasSlug.php
trait HasSlug
{
    public static function bootHasSlug(): void
    {
        static::creating(function ($model) {
            $model->slug = Str::slug($model->name);
        });
    }

    public function scopeBySlug(Builder $query, string $slug): Builder
    {
        return $query->where('slug', $slug);
    }
}
```

```php
// app/Models/Concerns/HasStatus.php
trait HasStatus
{
    public function scopeActive(Builder $query): Builder
    {
        return $query->where('status', 'active');
    }

    public function scopePending(Builder $query): Builder
    {
        return $query->where('status', 'pending');
    }

    public function isActive(): bool
    {
        return $this->status === 'active';
    }

    public function activate(): void
    {
        $this->update(['status' => 'active']);
    }
}
```

**使用基準**:
- 2つ以上のモデルで同じスコープ/メソッドが必要
- 単一責任を持つ機能群（Sluggable, Searchable, HasStatus等）
- boot処理を共有したい場合

### 3. Form Requests

バリデーションルールの共通化

```php
// app/Http/Requests/Concerns/HasEmailValidation.php
trait HasEmailValidation
{
    protected function emailRules(): array
    {
        return [
            'email' => ['required', 'email', 'max:255'],
        ];
    }
}

// app/Http/Requests/RegisterRequest.php
class RegisterRequest extends FormRequest
{
    use HasEmailValidation;

    public function rules(): array
    {
        return [
            ...$this->emailRules(),
            'name' => ['required', 'string', 'max:255'],
            'password' => ['required', 'min:8', 'confirmed'],
        ];
    }
}
```

### 4. Query Scopes

クエリパターンの再利用

```php
// app/Models/Concerns/Filterable.php
trait Filterable
{
    public function scopeFilter(Builder $query, array $filters): Builder
    {
        foreach ($filters as $field => $value) {
            if ($value !== null) {
                $query->where($field, $value);
            }
        }
        return $query;
    }

    public function scopeDateRange(Builder $query, ?string $from, ?string $to): Builder
    {
        return $query
            ->when($from, fn ($q) => $q->where('created_at', '>=', $from))
            ->when($to, fn ($q) => $q->where('created_at', '<=', $to));
    }
}
```

## React/TypeScript リファクタリングパターン

### 1. Custom Hooks

状態ロジックの抽出

```tsx
// hooks/useAsync.ts
function useAsync<T>(asyncFn: () => Promise<T>, deps: DependencyList = []) {
  const [state, setState] = useState<{
    data: T | null;
    loading: boolean;
    error: Error | null;
  }>({ data: null, loading: true, error: null });

  useEffect(() => {
    setState(s => ({ ...s, loading: true }));
    asyncFn()
      .then(data => setState({ data, loading: false, error: null }))
      .catch(error => setState({ data: null, loading: false, error }));
  }, deps);

  return state;
}

// 使用
const { data: users, loading, error } = useAsync(() => fetchUsers(), []);
```

**使用基準**:
- 2つ以上のコンポーネントで同じuseState/useEffect パターン
- 再利用可能な状態管理ロジック
- 副作用を伴う共通処理

### 2. Utility Functions

純粋関数の抽出

```tsx
// lib/format.ts
export function formatCurrency(amount: number, currency = 'JPY'): string {
  return new Intl.NumberFormat('ja-JP', {
    style: 'currency',
    currency,
  }).format(amount);
}

export function formatDate(date: Date | string, format = 'yyyy/MM/dd'): string {
  return new Intl.DateTimeFormat('ja-JP').format(new Date(date));
}

export function truncate(str: string, length: number): string {
  return str.length > length ? `${str.slice(0, length)}...` : str;
}
```

### 3. Compound Components

関連コンポーネントのグループ化

```tsx
// components/Card/index.tsx
const CardContext = createContext<{ variant: 'default' | 'elevated' }>({ variant: 'default' });

function Card({ children, variant = 'default' }: CardProps) {
  return (
    <CardContext.Provider value={{ variant }}>
      <div className={cn('rounded-lg', variant === 'elevated' && 'shadow-lg')}>
        {children}
      </div>
    </CardContext.Provider>
  );
}

Card.Header = function CardHeader({ children }: { children: ReactNode }) {
  return <div className="p-4 border-b">{children}</div>;
};

Card.Body = function CardBody({ children }: { children: ReactNode }) {
  return <div className="p-4">{children}</div>;
};

Card.Footer = function CardFooter({ children }: { children: ReactNode }) {
  return <div className="p-4 border-t">{children}</div>;
};

export { Card };
```

### 4. Higher-Order Components (HOC)

横断的関心事の抽出

```tsx
// hoc/withAuth.tsx
function withAuth<P extends object>(Component: ComponentType<P>) {
  return function AuthenticatedComponent(props: P) {
    const { auth } = usePage<PageProps>().props;

    if (!auth.user) {
      return <Navigate to="/login" />;
    }

    return <Component {...props} />;
  };
}

// 使用
export default withAuth(DashboardPage);
```

### 5. Render Props / Children as Function

柔軟な再利用パターン

```tsx
// components/DataFetcher.tsx
interface DataFetcherProps<T> {
  url: string;
  children: (data: T | null, loading: boolean, error: Error | null) => ReactNode;
}

function DataFetcher<T>({ url, children }: DataFetcherProps<T>) {
  const { data, loading, error } = useAsync<T>(() => fetch(url).then(r => r.json()), [url]);
  return <>{children(data, loading, error)}</>;
}

// 使用
<DataFetcher<User[]> url="/api/users">
  {(users, loading, error) => (
    loading ? <Spinner /> : <UserList users={users!} />
  )}
</DataFetcher>
```

## 検出コマンド

### PHP重複検出

```bash
# PHPCPDで重複検出（インストール: composer require --dev sebastian/phpcpd）
./vendor/bin/phpcpd app/ --min-lines=5 --min-tokens=70

# PHPStanでコード品質チェック
./vendor/bin/phpstan analyse app/ --level=max
```

### TypeScript/React重複検出

```bash
# jscpdで重複検出（インストール: npm install -g jscpd）
npx jscpd resources/js --min-lines 5 --reporters console

# ESLintでコード品質チェック
npm run lint
```

## リファクタリング判断基準

### 抽出すべき場合

| 条件 | 理由 |
|------|------|
| 3回以上の重複 | 維持コストが高い |
| 10行以上のブロック | 変更時の影響が大きい |
| ビジネスロジック | 一貫性が重要 |
| テストが必要な処理 | 単体テスト容易化 |
| 将来の変更が予想される | 単一変更点の確保 |

### 抽出を避けるべき場合

| 条件 | 理由 |
|------|------|
| 2回のみの重複 | 抽象化コストが高い |
| 3行以下のコード | 可読性が下がる |
| 偶発的類似 | 意味的に異なる可能性 |
| 異なる変更理由 | 不適切な結合 |

## 重複チェックリスト

コード作成/レビュー時に確認:

### PHP/Laravel
- [ ] 同じロジックが他のControllerに存在しないか → Modelメソッドに抽出
- [ ] 類似のバリデーションルールが他のFormRequestにないか → Trait化
- [ ] 同じクエリパターンが他のモデルにないか → Query Scope/Concernに抽出
- [ ] 既存のConcern（app/Models/Concerns/）で解決できないか
- [ ] Modelが肥大化しすぎていないか → 責務ごとにConcernに分離

### React/TypeScript
- [ ] 同じuseState/useEffectパターンが他のコンポーネントにないか → Custom Hook化
- [ ] 同じユーティリティ関数が別ファイルに定義されていないか → lib/に集約
- [ ] 既存のHook（hooks/）で解決できないか

## アンチパターン

### 過度な抽象化

```tsx
// BAD: 1回しか使わないのに抽象化
const useUserName = () => useState('');
const useUserEmail = () => useState('');

// GOOD: シンプルに保つ
const [name, setName] = useState('');
const [email, setEmail] = useState('');
```

### 不適切な共通化

```php
// BAD: 意味的に異なるものを無理に共通化
trait HasName
{
    public function getDisplayName(): string
    {
        // Userは "姓 名"、Productは "商品名" で全く異なる
        return $this->name;
    }
}

// GOOD: 各モデルで適切に実装
class User extends Model
{
    public function getDisplayName(): string
    {
        return "{$this->last_name} {$this->first_name}";
    }
}

class Product extends Model
{
    public function getDisplayName(): string
    {
        return $this->name;
    }
}
```

### 時期尚早な最適化

```tsx
// BAD: 最初から過度に汎用化
function useGenericCRUD<T extends BaseEntity>(
  endpoint: string,
  transform?: (data: T) => T,
  validate?: (data: T) => boolean,
  // ... 10個以上のオプション
) { ... }

// GOOD: 必要になってから抽象化
function useUsers() { ... }  // まずは具体的に
function useProducts() { ... }  // 重複が見えてきたら抽象化検討
```

## 自動修正の提案形式

重複検出時、以下の形式で提案:

```
重複コード検出

場所:
- app/Http/Controllers/UserController.php:45-52
- app/Http/Controllers/AdminController.php:78-85

重複タイプ: Type 2（パラメータ化重複）

推奨リファクタリング:
【単一モデル関連の場合】
1. app/Models/User.php にメソッドを追加
2. 各ControllerからModelメソッドを呼び出し

【複数モデル共通の場合】
1. app/Models/Concerns/HasXxx.php Traitを作成
2. 共通ロジックをTraitに抽出
3. 各Modelでuseして利用

変更例:
[コード例を提示]

考慮事項:
- Modelのテスト追加が必要
- 既存のConcernで対応可能か確認
```
