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

$indirectTest = function (): void {
    expect(true)->toBeTrue();
};

it('rejects an indirect callback', $indirectTest);

it('allows the scenario helper', function (): void {
    scenario('helper based test')
        ->given('a value', fn (): bool => true)
        ->when('the value is read', fn (bool $value): bool => $value)
        ->then('it remains true', fn (bool $result) => expect($result)->toBeTrue())
        ->run();
});
