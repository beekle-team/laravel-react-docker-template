// React 19 は compiler runtime を本体に同梱するため target 指定は不要
// （既定が "19"）。polyfill の react-compiler-runtime も要らない。
export const reactCompilerConfig = {};

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
