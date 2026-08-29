# Testing Rules

## Feature Test BDD

- 要件は docs/specs/{feature}/requirements.md にGherkinで記載する。
- Feature test変更前に対象scenarioとユーザー承認を確認する。
- Feature testはscenario() helperを使う。
- 1 scenarioずつRed → Green → Refactorし、失敗したまま次へ進まない。
- describeはUC-XX、itはScenario X.Y形式にする。

## Test Boundaries

- HTTP response / Inertia props: Pest Feature
- component / hook: Vitest
- 複数画面flow: Playwright
- 宣言的構造: Pest Arch
- 型解決が必要な呼び出し: PHPStan custom rule

## Exceptions

- Unit、Arch、Vitest、Playwrightはscenario()を要求しない。
