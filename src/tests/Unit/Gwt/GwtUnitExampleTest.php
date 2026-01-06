<?php

declare(strict_types=1);

/**
 * GWT パターンの Unit テスト例
 *
 * データベース不要なシンプルなロジックのテストでも
 * GWT パターンは有効です。
 */
describe('GWT Unit Test Examples', function () {
    describe('配列操作', function () {
        it('配列をフィルタリングできる', function () {
            scenario('偶数のみフィルタリング')
                ->given('数値の配列', fn () => [1, 2, 3, 4, 5, 6])
                ->when('偶数のみフィルタリングする', fn (array $numbers) => array_values(array_filter($numbers, fn ($n) => $n % 2 === 0)))
                ->then('偶数のみが残る', fn (array $result) => expect($result)->toBe([2, 4, 6]))
                ->run();
        });

        it('配列をマッピングできる', function () {
            scenario('配列の各要素を2倍にする')
                ->given('数値の配列', fn () => [1, 2, 3])
                ->when('各要素を2倍にする', fn (array $numbers) => array_map(fn ($n) => $n * 2, $numbers))
                ->then('すべての要素が2倍になる', fn (array $result) => expect($result)->toBe([2, 4, 6]))
                ->run();
        });
    });

    describe('文字列操作', function () {
        it('文字列を大文字に変換できる', function () {
            scenario('大文字変換')
                ->given('小文字の文字列', fn () => 'hello world')
                ->when('大文字に変換する', fn (string $text) => strtoupper($text))
                ->then('大文字になる', fn (string $result) => expect($result)->toBe('HELLO WORLD'))
                ->run();
        });

        it('文字列を分割できる', function () {
            scenario('カンマ区切り分割')
                ->given('カンマ区切りの文字列', fn () => 'apple,banana,cherry')
                ->when('カンマで分割する', fn (string $text) => explode(',', $text))
                ->then('配列になる', fn (array $result) => expect($result)->toBe(['apple', 'banana', 'cherry']))
                ->and('要素数は3つ', fn (array $result) => expect($result)->toHaveCount(3))
                ->run();
        });
    });

    describe('計算ロジック', function () {
        it('税込価格を計算できる', function () {
            $taxRate = 0.10;

            scenario('税込価格計算')
                ->given('税抜価格', fn () => 1000)
                ->when('税込価格を計算する', fn (int $price) => (int) ($price * (1 + $taxRate)))
                ->then('税込価格は1100円', fn (int $result) => expect($result)->toBe(1100))
                ->run();
        });

        it('割引価格を計算できる', function () {
            scenario('20%割引計算')
                ->given('元の価格', fn () => ['price' => 1000, 'discount' => 0.20])
                ->when('割引を適用する', fn (array $data) => (int) ($data['price'] * (1 - $data['discount'])))
                ->then('割引後価格は800円', fn (int $result) => expect($result)->toBe(800))
                ->run();
        });
    });

    describe('複数のGiven条件', function () {
        it('複数の前提条件を組み合わせられる', function () {
            scenario('複合条件でのテスト')
                ->given('ユーザー名', fn () => ['name' => 'John'])
                ->and('メールアドレス', fn () => ['email' => 'john@example.com'])
                ->and('年齢', fn () => ['age' => 30])
                ->when('ユーザー情報を生成する', fn (array $data) => sprintf('%s (%s) - %d歳', $data['name'], $data['email'], $data['age']))
                ->then('正しいフォーマットで出力される', fn (string $result) => expect($result)->toBe('John (john@example.com) - 30歳'))
                ->run();
        });
    });
});
