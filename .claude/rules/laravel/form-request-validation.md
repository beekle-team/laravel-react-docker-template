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

## 例外

`Auth::guard()->validate([...])` のような、Laravel 認証ガードや外部サービスの `validate` メソッドは対象外。
