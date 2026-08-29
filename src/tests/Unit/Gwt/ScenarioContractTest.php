<?php

declare(strict_types=1);

use PHPUnit\Framework\AssertionFailedError;
use Tests\Support\Gwt\Scenario;

it('Given より前に When を定義できない', function (): void {
    expect(fn () => new Scenario('invalid order')
        ->when('操作する', fn () => 'result'))
        ->toThrow(LogicException::class, 'Given');
});

it('When より前に Then を定義できない', function (): void {
    expect(fn () => new Scenario('invalid order')
        ->given('前提', fn () => 'context')
        ->then('結果', fn () => null))
        ->toThrow(LogicException::class, 'When');
});

it('When は一つだけ定義できる', function (): void {
    expect(fn () => new Scenario('multiple actions')
        ->given('前提', fn () => 'context')
        ->when('最初の操作', fn () => 'first')
        ->when('二つ目の操作', fn () => 'second'))
        ->toThrow(LogicException::class, 'When');
});

it('When の後に Given を追加できない', function (): void {
    expect(fn () => new Scenario('invalid order')
        ->given('前提', fn () => 'context')
        ->when('操作', fn () => 'result')
        ->given('遅すぎる前提', fn () => 'late'))
        ->toThrow(LogicException::class, 'Given');
});

it('Then がない Scenario は実行時に失敗する', function (): void {
    expect(fn () => new Scenario('missing expectation')
        ->given('前提', fn () => 'context')
        ->when('操作', fn () => 'result')
        ->run())
        ->toThrow(AssertionFailedError::class, 'Then');
});

it('有効な Given-When-Then を一度だけ実行できる', function (): void {
    $asserted = false;

    $scenario = new Scenario('valid scenario')
        ->given('値を準備', fn () => ['value' => 2])
        ->when('2倍にする', fn (array $context) => $context['value'] * 2)
        ->then('結果は4', function (int $result, array $context) use (&$asserted): void {
            expect($result)->toBe(4)
                ->and($context)->toBe(['value' => 2]);
            $asserted = true;
        });

    $scenario->run();

    expect($asserted)->toBeTrue()
        ->and(fn () => $scenario->run())
        ->toThrow(LogicException::class, '一度');
});
