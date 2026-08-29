---
globs: ["src/app/Http/Controllers/**/*.php","src/app/Http/Requests/**/*.php"]
---

# Form Request Validation

HTTP リクエストの入力検証は Form Request オブジェクト経由に統一する。

## 必須ルール

- Controller で `$request->validate([...])` を使わない
- Controller で `request()->validate([...])` を使わない
- バリデーションルールは `app/Http/Requests/**` 配下の `FormRequest` サブクラスの `rules()` に定義する
- Controller のアクション引数には用途別の Form Request を型指定する
- Controller では `$request->validated()` で検証済みデータを取得する
- Form Request を使う `POST` / `PUT` / `PATCH` / `DELETE` route には `HandlePrecognitiveRequests` middleware を付ける
- React の入力フォームは `@inertiajs/react` の `useForm(route, data)` または `.withPrecognition(method, url)` を使い、入力単位で `validate('field')` を呼ぶ

## 例

```php
// Good
public function store(StoreUserRequest $request): RedirectResponse
{
    $validated = $request->validated();
}

// Bad
public function store(Request $request): RedirectResponse
{
    $validated = $request->validate([
        'email' => ['required', 'email'],
    ]);
}
```

## Live Validation

Laravel Precognition を標準にする。Form Request のルールを二重実装せず、サーバ側のルールをそのままライブ検証に使う。

```php
use Illuminate\Foundation\Http\Middleware\HandlePrecognitiveRequests;

Route::post('/users', [UserController::class, 'store'])
    ->middleware(HandlePrecognitiveRequests::class);
```

```tsx
const form = useForm(storeUser(), {
    name: '',
    email: '',
});

<TextInput
    value={form.data.email}
    onChange={(event) => form.setData('email', event.target.value)}
    onBlur={() => form.validate('email')}
/>
```

## 強制

`tests/PHPStan/Rules/ControllerValidationRule.php`（カスタム PHPStan ルール）が
`App\Http\Controllers\**` 内の `Illuminate\Http\Request` 型レシーバに対する
`validate()` / `validateWithBag()` 呼び出しを検出する。変数名ではなく型で判定するため、
`$req` のように別名を付けても検出される。

## 例外

`Auth::guard()->validate([...])` のような、Laravel 認証ガードや外部サービスの `validate` メソッドは対象外。
レシーバが `Illuminate\Http\Request` でないため上記ルールには掛からない。
