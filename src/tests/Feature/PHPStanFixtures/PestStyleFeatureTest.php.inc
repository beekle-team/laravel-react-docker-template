<?php

declare(strict_types=1);

namespace Tests\Feature\PHPStanFixtures;

it('rejects direct assertions', function (): void {
    expect(true)->toBeTrue();
});

it('rejects a scenario that is not run', function (): void {
    scenario('incomplete helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue());
});

it('rejects an unused nested scenario', function (): void {
    expect(true)->toBeTrue();

    $unused = function (): void {
        scenario('unused helper based test')
            ->given('a value', fn (): bool => true)
            ->when('the value is read', fn (bool $value): bool => $value)
            ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
            ->run();
    };
});

it('rejects a valid scenario mixed with a nested scenario', function (): void {
    scenario('top-level helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();

    $unused = function (): void {
        scenario('nested helper based test')
            ->given('a value', fn (): bool => true)
            ->when('the value is read', fn (bool $value): bool => $value)
            ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
            ->run();
    };
});

it('rejects scenario steps in the wrong order', function (): void {
    scenario('wrong order helper based test')
        ->when('the value is read', fn (): bool => true)
        ->given('a value', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();
});

it('rejects multiple when steps', function (): void {
    scenario('multiple when helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->when('the value is read again', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();
});

it('rejects multiple top-level scenarios', function (): void {
    scenario('first helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();

    scenario('second helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();
});

it('rejects running a scenario twice', function (): void {
    scenario('double run helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run()
        ->run();
});

$indirectTest = function (): void {
    expect(true)->toBeTrue();
};

it('rejects an indirect callback', $indirectTest);

it('allows the scenario helper', function (): void {
    scenario('helper based test')
        ->given('a value', fn (): bool => true)
        ->and('another given value', fn (bool $value): bool => $value)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->and('it is still true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();
});
