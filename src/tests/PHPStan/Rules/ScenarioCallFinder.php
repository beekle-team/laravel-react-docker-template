<?php

declare(strict_types=1);

namespace Tests\PHPStan\Rules;

use PhpParser\Node;
use PhpParser\Node\Expr\ArrowFunction;
use PhpParser\Node\Expr\Closure;
use PhpParser\Node\Expr\FuncCall;
use PhpParser\Node\Expr\MethodCall;
use PhpParser\Node\Identifier;
use PhpParser\Node\Name;
use PhpParser\Node\Stmt\ClassMethod;
use PhpParser\Node\Stmt\Expression;
use PhpParser\NodeFinder;

final class ScenarioCallFinder
{
    public static function containsCompleteScenario(Node $node): bool
    {
        if ($node instanceof ArrowFunction) {
            return self::isCompleteScenarioChain($node->expr)
                && self::countScenarioCalls($node->expr) === 1;
        }

        if (! $node instanceof ClassMethod && ! $node instanceof Closure) {
            return false;
        }

        $completeScenarioCount = 0;
        $scenarioCallCount = 0;

        foreach ($node->stmts ?? [] as $statement) {
            $scenarioCallCount += self::countScenarioCalls($statement);

            if ($statement instanceof Expression && self::isCompleteScenarioChain($statement->expr)) {
                $completeScenarioCount++;
            }
        }

        return $completeScenarioCount === 1 && $scenarioCallCount === 1;
    }

    private static function isCompleteScenarioChain(Node $node): bool
    {
        if (! $node instanceof MethodCall) {
            return false;
        }

        $methods = [];
        $current = $node;

        while ($current instanceof MethodCall) {
            if (! $current->name instanceof Identifier) {
                return false;
            }

            $methods[] = strtolower($current->name->toString());
            $current = $current->var;
        }

        if (! $current instanceof FuncCall
            || ! $current->name instanceof Name
            || strtolower($current->name->getLast()) !== 'scenario') {
            return false;
        }

        return self::hasValidStepOrder(array_reverse($methods));
    }

    /** @param list<string> $methods */
    private static function hasValidStepOrder(array $methods): bool
    {
        $index = 0;

        if (($methods[$index] ?? null) !== 'given') {
            return false;
        }

        $index++;

        while (($methods[$index] ?? null) === 'and') {
            $index++;
        }

        if (($methods[$index] ?? null) !== 'when') {
            return false;
        }

        $index++;

        if (($methods[$index] ?? null) !== 'then') {
            return false;
        }

        $index++;

        while (($methods[$index] ?? null) === 'and') {
            $index++;
        }

        return ($methods[$index] ?? null) === 'run' && $index === count($methods) - 1;
    }

    private static function countScenarioCalls(Node $node): int
    {
        $finder = new NodeFinder;

        return count($finder->find(
            $node,
            fn (Node $candidate): bool => self::isScenarioCall($candidate),
        ));
    }

    private static function isScenarioCall(Node $node): bool
    {
        return $node instanceof FuncCall
            && $node->name instanceof Name
            && strtolower($node->name->getLast()) === 'scenario';
    }
}
