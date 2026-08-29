---
paths: ["src/app/Http/Controllers/**/*.php","src/app/Data/**/*.php","src/resources/js/**/*.ts","src/resources/js/**/*.tsx"]
---

# Inertia Props

Inertia で画面へ渡すモデル/API レスポンス由来の props は Laravel Data 経由に統一する。

## 必須ルール

- Eloquent Model や外部 API response をそのまま `Inertia::render()` に渡さない
- モデル/API レスポンス由来の構造化データは `app/Data/**` の Data クラスに変換する
- TypeScript の画面 props 型は `php artisan typescript:transform` で生成された `resources/js/types/generated.d.ts` から使う
- raw array は `Data::from()` / `Data::collect()` に置き換える

## 例外

- `canLogin` や `status` のような単純な scalar / boolean flag
- ページ表示だけで完結する一時的な enum 風文字列。ただし複数画面で使うなら Data / Enum 化する

## 判断フロー

1. DB レコード由来なら Eloquent Model から Data に変換する
2. 外部 API 由来なら Gateway Model の戻り値を Data に変換する
3. フロントで型が必要なら手書きせず `typescript:transform` で生成する
