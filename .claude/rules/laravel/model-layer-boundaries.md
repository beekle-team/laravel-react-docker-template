---
globs: ["src/app/**/*.php"]
---

# Model Layer Boundaries

アプリケーションの基本処理は Model 層に寄せる。Controller は HTTP 入出力、Form Request、認可、レスポンス制御に集中させる。

## Service / Action クラスは禁止

`app/Services/**` や `app/Actions/**` にユースケース処理を集めない。

Service クラスは禁止する。何でも入る便利な置き場になりやすく、責務境界が曖昧になって Controller の代わりに肥大化するため。

例外:

- Laravel の `ServiceProvider`
- フレームワークや外部ライブラリが要求する provider / contract 実装

## Eloquent Model

DB 永続化を持つものは `App\Models\Eloquent` の Eloquent Model に書く。ORM の責務は Eloquent に置く。

書くもの:

- relationships
- scopes
- casts
- accessor / mutator
- そのレコード自身の状態判定
- そのレコード自身の状態変更
- その Model の不変条件を守る処理

書かないもの:

- HTTP Request / Response 処理
- 外部 API 呼び出し
- provider 固有の認証や payload 組み立て
- 複数外部サービスの連携処理

## Gateway Model

外部サービス/API 接続は `App\Models\Gateway` に置く。インフラサービスは Gateway Model として表現し、Controller や Eloquent Model に通信仕様を漏らさない。

Gateway は `App\Models\Gateway\Model` を継承し、HTTP method validation、timeout、JSON response handling、HTTP error propagation は基底クラスに寄せる。provider 固有の header / auth / base URL は Gateway の `customPendingRequest()` や公開メソッドで閉じ込める。

書くもの:

- HTTP client 呼び出し
- endpoint / payload / response mapping
- provider 固有の認証
- provider 固有のエラー変換
- 外部リソースを表す軽量な Model
- `config/services.php` の provider 設定を読む接続情報

例:

- `App\Models\Gateway\OpenRouter\ChatCompletion`
- `App\Models\Gateway\SendGrid\Mail`
- `App\Models\Gateway\WebPush\Subscription`

Gateway Model は DB 永続化をしない。Eloquent Model から Gateway を直接呼ばず、Controller や job から明示的に両者を組み合わせる。

## Concerns / Traits

共通振る舞いは `App\Models\Concerns` の Trait に切り出す。

Trait / Concern を使う条件:

- 2 つ以上の Model で同じ振る舞いが必要
- 継承関係では表現しない方がよい
- 状態や責務が小さく閉じている
- Trait 名だけで責務が分かる

避けるもの:

- 1 つの Model でしか使っていない
- 外部 API 呼び出しを含む
- DB transaction を含む
- private / protected メソッド共有が主目的
- 便利メソッド置き場になっている

## 判断フロー

1. DB レコードそのものの話なら Eloquent Model に書く
2. 外部サービスのリソースや API 操作なら Gateway Model に書く
3. 複数 Model に共通する小さい性質なら Concern に切り出す
4. Controller は Form Request と Model 呼び出しだけに寄せる
5. 迷う場合も Service クラスは作らず、Eloquent / Gateway / Concern のどれの責務かを先に決める
