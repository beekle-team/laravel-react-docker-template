---
globs: ["src/tests/Arch/**/*.php","src/app/**/*.php","src/phpunit.xml"]
---

# Architecture Tests

`.claude/rules/**` に書いた設計ルールのうち、機械的に判定できるものは `tests/Arch/**` の Pest arch テストで強制する。文書だけのルールは守られないため、レビュー待ちにせず CI で落とす。

## 構成

| ファイル | 内容 |
| --- | --- |
| `tests/Arch/PresetsTest.php` | Pest の `php` / `security` / `laravel` preset |
| `tests/Arch/LayerBoundariesTest.php` | Model 層境界と Controller の責務（`model-layer-boundaries.md` / `form-request-validation.md` 由来） |
| `tests/Arch/CodingStandardsTest.php` | strict types（`php.md` 由来） |
| `tests/Arch/PrecognitionTest.php` | Form Request を使う変更系 route の Precognition middleware（`form-request-validation.md` 由来） |

`phpunit.xml` に `Arch` testsuite を定義してあるので、`php artisan test` で他のスイートと一緒に走る。arch だけ流すときは `php artisan test --testsuite=Arch`。

## 書き方

- 1 つの `arch()` に 1 つのルールを書き、説明文に日本語でルール名を書く。失敗時にどの規約に違反したか分かるようにする
- 対応する規約ファイルをコメントで示し、規約とテストが対で追えるようにする
- ディレクトリの不存在のように arch API で表現できないものは通常の `it()` で書く
- `laravel` preset は Eloquent Model 前提の検査を含むため、DB 永続化しない `App\Models\Gateway` は `ignoring()` で対象外にする

## 規約を追加したとき

`.claude/rules/**` に新しい設計ルールを追加したら、機械判定できるかを検討し、可能なら arch テストも足す。判定できない場合はレビュー観点として規約側に残す。

## BDD フローとの関係

`tests/Arch/**` は `.claude/rules/testing/feature-test-policy.md` の BDD フロー（requirements.md と Gherkin シナリオ必須）の対象外。ユーザー向け振る舞いではなく実装構造の検査なので、`scenario()` ヘルパーも使わない。
