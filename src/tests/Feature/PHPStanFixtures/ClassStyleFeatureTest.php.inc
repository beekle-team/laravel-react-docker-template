<?php

declare(strict_types=1);

namespace Tests\Feature\PHPStanFixtures;

use PHPUnit\Framework\TestCase;

final class ClassStyleFeatureTest extends TestCase
{
    public function test_direct_assertion_is_rejected(): void
    {
        self::assertTrue((bool) getenv('FEATURE_FLAG'));
    }

    public function test_scenario_without_then_is_rejected(): void
    {
        scenario('incomplete helper based test')
            ->given('a value', fn (): bool => true)
            ->when('the value is read', fn (bool $value): bool => $value)
            ->run();
    }

    public function test_unused_nested_scenario_is_rejected(): void
    {
        self::assertTrue((bool) getenv('FEATURE_FLAG'));

        $unused = function (): void {
            scenario('unused helper based test')
                ->given('a value', fn (): bool => true)
                ->when('the value is read', fn (bool $value): bool => $value)
                ->then('it remains true', fn (bool $result) => self::assertTrue($result))
                ->run();
        };
    }

    public function test_scenario_in_a_conditional_branch_is_rejected(): void
    {
        self::assertTrue((bool) getenv('FEATURE_FLAG'));

        if (getenv('RUN_SCENARIO') === 'yes') {
            scenario('conditionally executed helper based test')
                ->given('a value', fn (): bool => true)
                ->when('the value is read', fn (bool $value): bool => $value)
                ->then('it remains true', fn (bool $result) => self::assertTrue($result))
                ->run();
        }
    }

    public function test_scenario_helper_is_allowed(): void
    {
        scenario('helper based test')
            ->given('a value', fn (): bool => true)
            ->when('the value is read', fn (bool $value): bool => $value)
            ->then('it remains true', fn (bool $result) => self::assertTrue($result))
            ->run();
    }
}
