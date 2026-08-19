---
globs: ["src/resources/js/**/*.tsx","src/resources/js/**/*.ts","src/vite.config.js","src/package.json","src/knip.json"]
---

# React Compiler

React Compiler (`babel-plugin-react-compiler`) をビルドに常時適用する。メモ化はコンパイラに任せ、手書きの `useMemo` / `useCallback` / `memo` を既定にしない。

## セットアップ

- `vite.config.js` の `@vitejs/plugin-react` に Babel plugin として渡す。React Compiler は Babel pipeline の先頭で走らせる
- 本プロジェクトは React 18 なので `target: "18"` を指定し、`react-compiler-runtime` の polyfill を経由する。React 19 へ上げたら `target` 指定を外す
- `react-compiler-runtime` はソースから直接 import せずコンパイラ出力だけが参照するため、`knip.json` の `ignoreDependencies` に入れる

## コードの書き方

- 派生値・イベントハンドラ・子要素はそのまま書く。コンパイラが必要な箇所だけメモ化する
- 手動メモ化を足すのは、計測して効果が確認できた場合か、参照同一性が外部 API の契約になっている場合に限る
- コンパイラは Rules of React に従うコードだけ最適化する。render 中の props / state / 引数の変更、render 中の副作用、hooks の条件付き呼び出しを書かない
- 最適化されなかった component はビルドが壊れるのではなく最適化がスキップされるだけなので、段階的に直す

## Opt-out

コンパイラ適用で壊れる component は `"use no memo"` directive で一時的に除外できる。

```tsx
function LegacyWidget() {
    "use no memo";
    // ...
}
```

これは恒久対応ではない。原因の Rules of React 違反を直して directive を消す。

## 検証

- ビルド出力に `react.memo_cache_sentinel` が含まれていればコンパイラが効いている
- React DevTools では最適化された component に `Memo ✨` バッジが付く
