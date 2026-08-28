---
name: frontend-design
description: Create distinctive, production-grade frontend interfaces with high design quality. Use this skill when building web components, pages, or applications. Generates creative, polished code following modern design principles.
license: MIT
---

# Frontend Design Guide

このテンプレートの実際のスタックに沿って、質の高い UI を作るためのガイド。

**Stack**: React 19 + TypeScript + Inertia.js v2 + Tailwind CSS v4 + Headless UI
**Keywords**: frontend, react, design, UI, components, inertia, tailwind

配置ルールは `.claude/rules/frontend/architecture.md` が正本。このファイルは見た目の作り方だけを扱う。

## Design Context

新しい画面を作る前に確認する。

- 誰がどの頻度で使う画面か
- 一覧 / 入力 / 確認 / 結果のどれか
- 読み込み中・空・エラーの 3 状態をどう出すか
- キーボードだけで完了できるか

## Design Tokens

Tailwind v4 は CSS-first 設定。token は `resources/css/app.css` の `@theme` に定義し、コンポーネントからは通常の Tailwind utility として参照する。`tailwind.config.js` は存在しないので作らない。

```css
/* resources/css/app.css */
@import "tailwindcss";

@theme {
    --font-sans: Figtree, ui-sans-serif, system-ui, sans-serif;

    --color-brand-500: oklch(58% 0.2 250);
    --color-brand-600: oklch(50% 0.18 250);

    --radius-card: 0.75rem;
}
```

```tsx
<button className="bg-brand-500 hover:bg-brand-600 rounded-card px-4 py-2 text-white">
    保存
</button>
```

やること:

- 繰り返し使う色・角丸・影は `@theme` に足してから使う
- 一度きりの装飾値だけ arbitrary value (`w-[37px]`) を許す
- 2 回目に同じ値が出たら token へ昇格する

やらないこと:

- コンポーネント内に hex を直書きする
- 存在しない token 名 (`font-display` など) を使う
- 画面名を token 名に入れる (`--color-login-bg`)

## Typography

- 本文とラベルは `font-sans` (`--font-sans`)。既定は Figtree
- 別の書体を足す場合は `@theme` に `--font-display` などを定義してから `font-display` を使う
- 日本語を扱う画面では、長い語が container を押し広げないよう `truncate` / `break-words` の方針を決める

## Color

- 状態は色だけで表さない。アイコンかラベルを添える
- テキストと背景のコントラストは WCAG 2.1 AA (4.5:1、大きい文字は 3:1) を満たす
- semantic な名前を付ける (`--color-danger-500`)。`--color-red-2` のような並び番号にしない

## Interaction

- Headless UI (`@headlessui/react`) が入っている。Dialog / Menu / Combobox など focus trap と ARIA が要る UI は自作せずこれを使う
- すべての interactive 要素に default / hover / focus-visible / active / disabled を用意する
- `focus:outline-none` だけ書いて終わらせない。`focus-visible:ring-2` などの代替を必ず置く
- 非同期操作には loading 状態を出し、二重送信を防ぐ

## Motion

- animation ライブラリは入れていない。CSS transition と Tailwind の `transition-*` / `animate-*` で組む
- 動きは 150-250ms 程度に収める
- `prefers-reduced-motion` を尊重する

```tsx
<div className="transition-opacity duration-200 motion-reduce:transition-none">
```

## Component Hierarchy

`.claude/rules/frontend/architecture.md` の区分に従う。

| 種類 | 置き場所 |
|---|---|
| Inertia page entry | `Pages/**` |
| feature 固有 UI / hook | `features/{feature}/components`, `features/{feature}/hooks` |
| 2 箇所以上で使う汎用 UI | `shared/components` |
| app shell / layout | `Layouts/**` |

feature をまたいで内部 component を直接 import しない。共有が必要になった時点で `shared` へ上げる。

## Forms

- 入力検証は Laravel の Form Request が正本。フロントで rule を二重実装しない
- `@inertiajs/react` の `useForm` と Precognition を使い、`onBlur` で `validate('field')` を呼ぶ
- error は field 直下に赤文字で出し、`aria-invalid` と `aria-describedby` を付ける

## Best Practices

DO:

- `@theme` の token を使う
- 状態 (loading / empty / error) を最初から作る
- `focus-visible` を残す
- 画像に `alt`、icon-only button に `aria-label` を付ける
- 日本語 copy は呼び出し側から props で渡す

DON'T:

- 存在しないモジュール (`@/design-system/theme` など) を import する
- hex / px をコンポーネントに直書きする
- `any` を使う (`.claude/rules/type-safety.md`)
- 手書きの型を `resources/js/types/**` に足す
- Headless UI で足りる UI を自作する

## Example

```tsx
import { type ReactNode } from "react";

type CardProps = {
    title: string;
    description?: string;
    action?: ReactNode;
};

export function Card({ title, description, action }: CardProps) {
    return (
        <section className="rounded-card border border-gray-200 bg-white p-6 shadow-sm transition-shadow duration-200 hover:shadow-md motion-reduce:transition-none">
            <h3 className="text-lg font-semibold text-gray-900">{title}</h3>
            {description ? <p className="mt-2 text-sm text-gray-600">{description}</p> : null}
            {action ? <div className="mt-4">{action}</div> : null}
        </section>
    );
}
```

## Quality Checklist

画面を出す前に確認する。

- [ ] `@theme` の token だけで色・角丸・影を表現した
- [ ] loading / empty / error の 3 状態がある
- [ ] キーボードだけで操作でき、focus が見える
- [ ] コントラストが AA を満たす
- [ ] 320px 幅で横スクロールしない
- [ ] `npm run lint:js` / `npm run types` / `npm run lint:react-compiler` が通る
