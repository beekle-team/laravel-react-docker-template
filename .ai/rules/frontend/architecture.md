---
paths: ["src/resources/js/**/*.tsx","src/resources/js/**/*.ts"]
---

# React Frontend Architecture

React 側は Inertia の Pages を入口として残しつつ、feature-based architecture で整理する。

## 基本構成

```txt
resources/js/
  app.tsx
  Pages/
  Components/
  Layouts/
  features/
  shared/
  types/
  actions/
  routes/
  wayfinder/
```

## Inertia Pages

`Pages/**` は Inertia の page entry として扱う。

書くもの:

- Laravel の `Inertia::render()` から直接解決される page component
- page 全体の composition
- layout の適用
- feature component への props 接続

避けるもの:

- 大きな業務ロジック
- feature 固有 UI の増殖
- `Pages/**/Partials` の継続的な肥大化

`Pages` はなくさない。Inertia のルーティング境界として残す。

既存の `Pages/**/Partials` は段階的移行対象とする。新規 feature 固有 UI / hooks / helpers は `features/{feature}` へ作り、既存 Partials は触るタイミングで feature 配下へ寄せる。

## Features

feature 固有の UI、hooks、helper、型は `features/{feature}` に置く。

```txt
features/
  auth/
    components/
    hooks/
    types.ts
  profile/
    components/
    hooks/
    types.ts
```

書くもの:

- その feature だけで使う component
- その feature だけで使う hook
- その feature だけで使う form/helper
- その feature だけで使う TypeScript type

避けるもの:

- 他 feature から内部 component を直接 import する
- 汎用 component を feature 配下に置く
- `shared` に業務固有の処理を逃がす

## Shared

複数 feature から使うものだけ `shared/**` に置く。

```txt
shared/
  components/
  hooks/
  lib/
  types/
```

`shared` は汎用置き場ではない。2 箇所以上で実際に再利用されてから移す。

## Existing Directories

- `Components/**`: 既存の汎用 UI component。新規の業務固有 component は置かない
- `Layouts/**`: app shell / page layout
- `types/generated.d.ts`: Laravel Data などから生成される型。手編集しない
- `actions/**`, `routes/**`, `wayfinder/**`: Wayfinder 生成物。手編集しない

## Import Rules

- `Pages/**` は `features/**` と `shared/**` を import してよい
- `features/{a}` から `features/{b}` の内部実装を import しない
- feature 間で共有が必要になったら `shared/**` に昇格する
- 生成物は `actions/**` / `routes/**` から利用し、手書きルート文字列を増やさない

## 判断フロー

1. Inertia から直接表示される画面なら `Pages/**`
2. 特定 feature に閉じる UI / hook / helper なら `features/{feature}/**`
3. 複数 feature で再利用する表示・hook・util なら `shared/**`
4. アプリ全体の枠なら `Layouts/**`
5. 生成された型や route/action は生成物ディレクトリを使い、手編集しない
