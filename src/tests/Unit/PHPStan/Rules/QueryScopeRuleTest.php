<?php

declare(strict_types=1);

namespace Tests\Unit\PHPStan\Rules;

use PHPStan\Rules\Rule;
use PHPStan\Testing\RuleTestCase;
use PHPUnit\Framework\Attributes\WithoutErrorHandler;
use Tests\PHPStan\Rules\QueryScopeRule;

/** @extends RuleTestCase<QueryScopeRule> */
final class QueryScopeRuleTest extends RuleTestCase
{
    protected function getRule(): Rule
    {
        return new QueryScopeRule;
    }

    #[WithoutErrorHandler]
    public function test_both_scope_styles_without_rejecting_collection_reads(): void
    {
        $prefix = 'App\\Models\\Eloquent\\ArchitectureFixture\\ScopedRecord::';
        $suffix = '() は禁止。検索条件だけを組み立て、実行・副作用・HTTPコンテキスト依存は呼び出し側へ移す。';
        $this->analyse([__DIR__.'/../../../PHPStan/Fixtures/QueryScopeFixture.php'], [
            [$prefix.'scopePending(): Scope 内の get'.$suffix, 18],
            [$prefix.'scopePending(): Scope 内の auth'.$suffix, 19],
            [$prefix.'visible(): Scope 内の first'.$suffix, 26],
            [$prefix.'visible(): Scope 内の request'.$suffix, 27],
            [$prefix.'visible(): Scope 内の update'.$suffix, 28],
        ]);
    }
}
