<?php

declare(strict_types=1);

namespace Tests\PHPStan\Rules;

use PhpParser\Node;
use PhpParser\Node\Arg;
use PhpParser\Node\Expr\ArrowFunction;
use PhpParser\Node\Expr\Closure;
use PhpParser\Node\Expr\FuncCall;
use PhpParser\Node\Name;
use PHPStan\Analyser\Scope;
use PHPStan\Rules\IdentifierRuleError;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;

/** @implements Rule<FuncCall> */
final class FeaturePestTestUsesScenarioRule implements Rule
{
    public function getNodeType(): string
    {
        return FuncCall::class;
    }

    /** @return list<IdentifierRuleError> */
    public function processNode(Node $node, Scope $scope): array
    {
        if (! $this->isFeatureTestFile($scope->getFile())
            || ! $node->name instanceof Name
            || ! in_array(strtolower($node->name->getLast()), ['it', 'test'], true)
            || ! isset($node->args[1])
            || ! $node->args[1] instanceof Arg) {
            return [];
        }

        $testBody = $node->args[1]->value;

        if (! $testBody instanceof Closure && ! $testBody instanceof ArrowFunction) {
            return [$this->error($node->getStartLine())];
        }

        if (ScenarioCallFinder::containsCompleteScenario($testBody)) {
            return [];
        }

        return [$this->error($node->getStartLine())];
    }

    private function error(int $line): IdentifierRuleError
    {
        return RuleErrorBuilder::message('Feature テストは scenario() ヘルパーを使い、Given-When-Then 形式で記述してください。')
            ->identifier('testing.featureScenarioRequired')
            ->line($line)
            ->build();
    }

    private function isFeatureTestFile(string $file): bool
    {
        return str_contains(str_replace('\\', '/', $file), '/tests/Feature/');
    }
}
