---
paths: ["src/resources/js/**/*.tsx","src/resources/js/**/*.ts","src/vite.config.js","src/react-compiler.config.js","src/scripts/check-react-compiler.mjs","src/package.json","src/knip.json"]
---

# React Compiler

React Compiler (`babel-plugin-react-compiler`) をビルドに常時適用する。メモ化はコンパイラに任せ、手書きの `useMemo` / `useCallback` / `memo` を既定にしない。

## セットアップ

- コンパイラ設定は `react-compiler.config.js` に置き、ビルド (`vite.config.js`) と CI 検査 (`scripts/check-react-compiler.mjs`) の両方が同じ設定を import する。設定を二重に書かない
- `vite.config.js` の `@vitejs/plugin-react` に Babel plugin として渡す。React Compiler は Babel pipeline の先頭で走らせる
- React 19 は compiler runtime を本体に同梱するため `target` 指定は不要（既定が `"19"`）。コンパイラ出力は `react/compiler-runtime` から import する。React 17 / 18 に戻す場合だけ `target` と `react-compiler-runtime` の polyfill が必要になる
- `@vitejs/plugin-react` はインライン `babel` オプションを使う 4.x 系に固定する。Vite 7 を peerDependencies に含むのは 4.5.2 以降なので、宣言範囲を lockfile の解決版と揃える。v6 系へ上げる場合は `@rolldown/plugin-babel` + `reactCompilerPreset` への移行が必要

## コードの書き方

- 派生値・イベントハンドラ・子要素はそのまま書く。コンパイラが必要な箇所だけメモ化する
- 手動メモ化を足すのは、計測して効果が確認できた場合か、参照同一性が外部 API の契約になっている場合に限る
- コンパイラは Rules of React に従うコードだけ最適化する。render 中の props / state / 引数の変更、render 中の副作用、hooks の条件付き呼び出しを書かない
- 最適化されなかった component はビルドが壊れるのではなく最適化がスキップされるだけなので、段階的に直す

## Opt-out

コンパイラ適用で壊れる component は `"use no memo"` directive で一時的に除外できる。関数単位とファイル単位のどちらでも書ける。

```tsx
function LegacyWidget() {
    "use no memo";
    // ...
}
```

これは恒久対応ではない。原因の Rules of React 違反を直して directive を消す。opt-out した件数は後述の CI 検査がサマリに出すので、増え続けていないか確認する。

## CI 検査

`npm run lint:react-compiler` で、ビルドと同じコンパイラを `resources/js/**` に対して走らせ、最適化がスキップされた箇所を検出する。ビルドはスキップしても成功してしまうため、この検査がないと最適化の欠落に気づけない。

- 検出対象は `CompileError` / `CompileSkip` / `PipelineError` / `CompileDiagnostic`。1 件でもあれば exit 1
- `"use no memo"` で明示的に除外した関数とファイルは失敗にせず、opt-out 件数としてサマリに出す
- ビルド設定より厳しい validation（render 中の不純関数、手動メモ化の保証、effect 内 setState / 派生計算）を検査側だけで有効化している
- React Compiler の ESLint ルール (`eslint-plugin-react-hooks`) は導入していない。このリポジトリのフロント lint は Biome に統一しており、コンパイル阻害要因はこの検査で同等のメッセージが得られるため

## 検証

- ビルド出力に `react.memo_cache_sentinel` が含まれていればコンパイラが効いている
- React DevTools では最適化された component に `Memo ✨` バッジが付く
