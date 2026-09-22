<?php

declare(strict_types=1);

namespace Tests\Unit\PHPStan\Rules;

use App\Http\Controllers\ArchitectureFixture\ExampleController;
use PHPStan\Rules\Rule;
use PHPStan\Testing\RuleTestCase;
use PHPUnit\Framework\Attributes\WithoutErrorHandler;
use Tests\PHPStan\Rules\LayerBoundaryRule;

/** @extends RuleTestCase<LayerBoundaryRule> */
final class LayerBoundaryRuleTest extends RuleTestCase
{
    protected function getRule(): Rule
    {
        require_once __DIR__.'/../../../PHPStan/Fixtures/LayerBoundaryFixture.php';

        return new LayerBoundaryRule;
    }

    #[WithoutErrorHandler]
    public function test_boundaries_and_allowed_domain_delegation(): void
    {
        $controller = ExampleController::class;
        $write = '永続化・状態変更は Eloquent Model の業務メソッドへ移す。';
        $external = '外部通信・SDK操作は Gateway へ移す。';
        $this->analyse([__DIR__.'/../../../PHPStan/Fixtures/LayerBoundaryFixture.php'], [
            [$controller.'::save(): '.$write, 17],
            [$controller.'::delete(): '.$write, 18],
            [$controller.'::transaction(): DB操作・トランザクションは Eloquent Model または横断処理を担う Support へ移す。', 19],
            [$controller.'::lock(): 排他制御は状態変更を所有する Model または Support へ移す。', 20],
            [$controller.'::get(): '.$external, 21],
            [$controller.'::post(): '.$external, 22],
            ['App\\Models\\Gateway\\ArchitectureFixture\\ExampleGateway::update(): '.$write, 41],
            ['App\\Models\\Eloquent\\ArchitectureFixture\\ExampleModel::get(): '.$external, 53],
        ]);
    }
}
