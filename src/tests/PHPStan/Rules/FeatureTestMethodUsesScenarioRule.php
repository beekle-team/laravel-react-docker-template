<?php

declare(strict_types=1);

namespace Tests\PHPStan\Rules;

use PhpParser\Node;
use PhpParser\Node\Stmt\ClassMethod;
use PHPStan\Analyser\Scope;
use PHPStan\Reflection\ClassReflection;
use PHPStan\Rules\IdentifierRuleError;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;
use PHPStan\Type\ObjectType;
use PHPUnit\Framework\TestCase;

/** @implements Rule<ClassMethod> */
final class FeatureTestMethodUsesScenarioRule implements Rule
{
    public function getNodeType(): string
    {
        return ClassMethod::class;
    }

    /** @return list<IdentifierRuleError> */
    public function processNode(Node $node, Scope $scope): array
    {
        if (! $this->isFeatureTestFile($scope->getFile())
            || ! $node->isPublic()
            || ! $this->isTestMethod($node)
            || ! $this->isPhpUnitTestCase($scope->getClassReflection())
            || ScenarioCallFinder::containsCompleteScenario($node)) {
            return [];
        }

        return [$this->error($node->getStartLine())];
    }

    private function isFeatureTestFile(string $file): bool
    {
        return str_contains(str_replace('\\', '/', $file), '/tests/Feature/');
    }

    private function isTestMethod(ClassMethod $method): bool
    {
        if (str_starts_with(strtolower($method->name->toString()), 'test')) {
            return true;
        }

        foreach ($method->attrGroups as $attributeGroup) {
            foreach ($attributeGroup->attrs as $attribute) {
                if (strtolower($attribute->name->getLast()) === 'test') {
                    return true;
                }
            }
        }

        return preg_match('/@test\b/i', $method->getDocComment()?->getText() ?? '') === 1;
    }

    private function isPhpUnitTestCase(?ClassReflection $class): bool
    {
        return $class instanceof ClassReflection
            && new ObjectType(TestCase::class)->isSuperTypeOf(new ObjectType($class->getName()))->yes();
    }

    private function error(int $line): IdentifierRuleError
    {
        return RuleErrorBuilder::message('Feature テストは scenario() ヘルパーを使い、Given-When-Then 形式で記述してください。')
            ->identifier('testing.featureScenarioRequired')
            ->line($line)
            ->build();
    }
}
