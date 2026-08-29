---
paths: ["src/tests/Arch/**/*.php","src/tests/PHPStan/**/*.php","src/app/**/*.php","src/phpunit.xml","src/phpstan.neon"]
---

# Architecture Tests

`.ai/rules/**` に書いた設計ルールのうち、機械的に判定できるものは CI で強制する。文書だけのルールは守られないため、レビュー待ちにせず落とす。

強制の置き場は 2 つある。

| 判定に必要なもの | 置き場 | 例 |
| --- | --- | --- |
| クラスの有無・継承・依存・命名 | `tests/Arch/**` の Pest arch テスト | Service クラス禁止、Gateway は DB を触らない、Concerns は trait |
| 式や呼び出しの構造（型の解決が要る） | `tests/PHPStan/Rules/**` のカスタム PHPStan ルール | Controller での `$request->validate()` 禁止 |

arch テストで書けるものは arch テストに置く。宣言的で読めるため。arch API では表現できず、レシーバの型を解決しないと判定できないものだけ PHPStan ルールにする。PHPStan なら失敗が「テストが落ちた」ではなく `NewPasswordController.php:43` という位置付きで出て、エディタにも表示される。

## 構成

| ファイル | 内容 |
| --- | --- |
| `tests/Arch/PresetsTest.php` | Pest の `php` / `security` / `laravel` preset |
| `tests/Arch/LayerBoundariesTest.php` | Model 層境界と Controller の責務（`model-layer-boundaries.md` / `form-request-validation.md` 由来） |
| `tests/Arch/CodingStandardsTest.php` | strict types（`php.md` 由来） |
| `tests/Arch/PrecognitionTest.php` | Form Request を使う変更系 route の Precognition middleware（`form-request-validation.md` 由来） |
| `tests/PHPStan/Rules/ControllerValidationRule.php` | Controller での `$request->validate()` / `request()->validate()` 禁止（`form-request-validation.md` 由来） |
| `tests/PHPStan/Rules/FeatureTestMethodUsesScenarioRule.php` | PHPUnit形式のFeature testに完全なGWT Scenarioを強制（`.ai/rules/testing.md` 由来） |
| `tests/PHPStan/Rules/FeaturePestTestUsesScenarioRule.php` | Pest形式のFeature testに完全なGWT Scenarioを強制（`.ai/rules/testing.md` 由来） |
| `tests/PHPStan/Rules/ScenarioCallFinder.php` | `scenario()->given()->when()->then()->run()`チェーンの共通検出 |

`phpunit.xml` に `Arch` testsuite を定義してあるので、`php artisan test` で他のスイートと一緒に走る。arch だけ流すときは `php artisan test --testsuite=Arch`。

## 書き方

- 1 つの `arch()` に 1 つのルールを書き、説明文に日本語でルール名を書く。失敗時にどの規約に違反したか分かるようにする
- 対応する規約ファイルをコメントで示し、規約とテストが対で追えるようにする
- ディレクトリの不存在のように arch API で表現できないものは通常の `it()` で書く
- 呼び出しの検査は arch テストに書かない。`token_get_all()` で自前にトークンを走査すると変数名でしか判定できず、`$req->validate()` のような別名を取り逃がす。レシーバの型で判定できる PHPStan のカスタムルールに置く
- `laravel` preset は Eloquent Model 前提の検査を含むため、DB 永続化しない `App\Models\Gateway` は `ignoring()` で対象外にする

## カスタム PHPStan ルール

`tests/PHPStan/Rules/**` に `PHPStan\Rules\Rule` の実装を置き、`phpstan-rules.neon` の `rules:` に登録する。`phpstan.neon` とfixture用設定はこの共通ファイルを読み込む。namespace は `Tests\PHPStan\Rules`（composer の `autoload-dev` の `Tests\` に乗る）。

- `getNodeType()` で対象ノードを絞り、`processNode()` で違反だけ `RuleErrorBuilder` で返す
- `identifier()` は必須。`laravel.controllerValidation` のように規約が分かる名前を付ける
- メッセージは日本語で「何をやめて何をするか」まで書く。位置は PHPStan が付ける
- 変数名ではなく `$scope->getType()` の型で判定する。これが arch テストや正規表現に対する優位点

## 規約を追加したとき

`.ai/rules/**` に新しい設計ルールを追加したら、機械判定できるかを検討し、可能なら arch テストかカスタム PHPStan ルールを足す。判定できない場合はレビュー観点として規約側に残す。

## BDD フローとの関係

`tests/Arch/**` は `.ai/rules/testing.md` の BDD フロー（requirements.md と Gherkin シナリオ必須）の対象外。ユーザー向け振る舞いではなく実装構造の検査なので、`scenario()` ヘルパーも使わない。
