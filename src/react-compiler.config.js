// React 18 では compiler runtime が react 本体に同梱されないため、
// react-compiler-runtime の polyfill を使う target を明示する。
export const reactCompilerConfig = {
    target: "18",
};

// ビルドは最適化をスキップしても失敗しない設計なので、CI 用の検査では
// 既定で無効な validation を上乗せして Rules of React 違反を検知する。
export const reactCompilerCheckConfig = {
    ...reactCompilerConfig,
    noEmit: true,
    environment: {
        validateNoImpureFunctionsInRender: true,
        validatePreserveExistingMemoizationGuarantees: true,
        validateNoSetStateInEffects: true,
        validateNoDerivedComputationsInEffects: true,
    },
};
