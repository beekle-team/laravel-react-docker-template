# Testing Rules

## Feature Test BDD

- 要件は docs/specs/{feature}/requirements.md にGherkinで記載する。
- Feature test変更前に対象scenarioとユーザー承認を確認する。
- Feature testはscenario() helperを使う。
- 1 scenarioずつRed → Green → Refactorし、失敗したまま次へ進まない。
- describeはUC-XX、itはScenario X.Y形式にする。

## Executable Scenario Contract

- `Given` は最低1つ必要。
- `When` は業務上の主操作としてちょうど1つ必要。
- `Then` は最低1つ必要で、外部から観測可能な結果を検証する。
- 順序は `Given → When → Then` とする。
- `And` は Given または Then の追加にだけ使い、When の追加操作には使わない。
- `run()` は最後に1回だけ呼ぶ。
- Thenなし、順序違反、複数When、二重実行はテスト失敗とする。
- 複数の主操作が必要な場合はScenarioを分割するか、単一の業務操作として表現できる境界を見直す。

## Test Boundaries

- HTTP response / Inertia props: Pest Feature
- component / hook: Vitest
- 複数画面flow: Playwright
- 宣言的構造: Pest Arch
- 型解決が必要な呼び出し: PHPStan custom rule

## Exceptions

- Unit、Arch、Vitest、Playwrightはscenario()を要求しない。
