<?php

declare(strict_types=1);

namespace Tests\PHPStan\Rules;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Database\Query\Builder as QueryBuilder;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use PhpParser\Node;
use PhpParser\Node\Expr;
use PHPStan\Analyser\Scope;
use PHPStan\Reflection\ExtendedMethodReflection;
use PHPStan\Rules\IdentifierRuleError;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;
use PHPStan\Type\ObjectType;

/** @implements Rule<Expr> */
final class QueryScopeRule implements Rule
{
    public function getNodeType(): string
    {
        return Expr::class;
    }

    /** @return list<IdentifierRuleError> */
    public function processNode(Node $node, Scope $scope): array
    {
        $owner = $scope->getClassReflection()?->getName() ?? '';
        $function = $scope->getFunction();
        if (! str_starts_with($owner, 'App\\Models\\') || ! $function instanceof ExtendedMethodReflection) {
            return [];
        }

        $isScope = preg_match('/^scope[A-Z]/', $function->getName()) === 1;
        foreach ($function->getAttributes() as $attribute) {
            $isScope = $isScope || $attribute->getName() === \Illuminate\Database\Eloquent\Attributes\Scope::class;
        }

        if (! $isScope) {
            return [];
        }

        $forbidden = null;
        if ($node instanceof Expr\FuncCall && $node->name instanceof Node\Name
            && in_array(strtolower($node->name->toString()), ['auth', 'request'], true)) {
            $forbidden = $node->name->toString();
        }

        if (($node instanceof Expr\MethodCall || $node instanceof Expr\StaticCall)
            && $node->name instanceof Node\Identifier) {
            $type = $node instanceof Expr\StaticCall
                ? ($node->class instanceof Node\Name ? new ObjectType($scope->resolveName($node->class)) : $scope->getType($node->class))
                : $scope->getType($node->var);
            $orm = false;
            foreach ([Model::class, Builder::class, QueryBuilder::class, Relation::class] as $base) {
                $orm = $orm || new ObjectType($base)->isSuperTypeOf($type)->yes();
            }

            if ($orm && in_array(strtolower($node->name->toString()), [
                'get', 'first', 'firstorfail', 'find', 'findorfail', 'sole', 'all', 'pluck', 'value',
                'count', 'exists', 'doesntexist', 'sum', 'avg', 'min', 'max', 'paginate', 'simplepaginate',
                'cursorpaginate', 'cursor', 'lazy', 'lazybyid', 'chunk', 'chunkbyid', 'each',
                'save', 'savequietly', 'saveorfail', 'update', 'updatequietly', 'delete', 'deletequietly',
                'create', 'createquietly', 'insert', 'insertgetid', 'upsert', 'increment', 'decrement',
                'firstorcreate', 'createorfirst', 'updateorcreate', 'destroy', 'forcedelete', 'restore',
                'attach', 'detach', 'sync', 'toggle', 'push', 'fill', 'forcefill', 'truncate',
            ], true)) {
                $forbidden = $node->name->toString();
            }

            foreach ($type->getObjectClassNames() as $target) {
                if (str_starts_with($target, 'App\\Models\\Gateway\\')
                    || str_starts_with($target, 'Stripe\\')
                    || str_starts_with($target, 'GuzzleHttp\\')
                    || str_starts_with($target, 'Illuminate\\Http\\Client\\')
                    || in_array($target, [
                        Auth::class, \Illuminate\Support\Facades\Request::class,
                        Http::class, DB::class,
                        Request::class,
                    ], true)) {
                    $forbidden = $target.'::'.$node->name->toString();
                }
            }
        }

        if ($forbidden === null) {
            return [];
        }

        return [RuleErrorBuilder::message(sprintf(
            '%s::%s(): Scope 内の %s() は禁止。検索条件だけを組み立て、実行・副作用・HTTPコンテキスト依存は呼び出し側へ移す。',
            $owner, $function->getName(), $forbidden,
        ))->identifier('architecture.queryScope')->build()];
    }
}
