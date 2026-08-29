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

final class ScenarioCallFinder
{
    public static function containsCompleteScenario(Node $node): bool
    {
        if ($node instanceof ArrowFunction) {
            return self::isCompleteScenarioChain($node->expr);
        }

        if (! $node instanceof ClassMethod && ! $node instanceof Closure) {
            return false;
        }

        return array_any(
            $node->stmts ?? [],
            fn (Node $statement): bool => $statement instanceof Expression
                && self::isCompleteScenarioChain($statement->expr),
        );
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

        return array_diff(['given', 'when', 'then', 'run'], $methods) === [];
    }
}
