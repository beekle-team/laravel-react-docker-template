<?php

declare(strict_types=1);

namespace Tests\PHPStan\Rules;

use Illuminate\Database\Connection;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\Relation;
use Illuminate\Database\Query\Builder as QueryBuilder;
use Illuminate\Http\RedirectResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Inertia\Inertia;
use PhpParser\Node;
use PhpParser\Node\Expr;
use PHPStan\Analyser\Scope;
use PHPStan\Rules\IdentifierRuleError;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;
use PHPStan\Type\ObjectType;

/** @implements Rule<Expr> */
final class LayerBoundaryRule implements Rule
{
    private const array WRITES = [
        'save', 'savequietly', 'saveorfail', 'update', 'updatequietly', 'updateorfail',
        'create', 'createquietly', 'forcecreate', 'firstorcreate', 'createorfirst', 'updateorcreate',
        'insert', 'insertgetid', 'insertorignore', 'upsert', 'delete', 'deletequietly',
        'destroy', 'forcedelete', 'forcedestroy', 'restore', 'restorequietly', 'truncate',
        'increment', 'decrement', 'incrementquietly', 'decrementquietly',
        'attach', 'detach', 'sync', 'syncwithoutdetaching', 'toggle', 'updateexistingpivot',
        'push', 'pushquietly', 'savemany', 'createmany', 'fill', 'forcefill',
    ];

    public function getNodeType(): string
    {
        return Expr::class;
    }

    /** @return list<IdentifierRuleError> */
    public function processNode(Node $node, Scope $scope): array
    {
        $owner = $scope->getClassReflection()?->getName() ?? '';
        if (! str_starts_with($owner, 'App\\')) {
            return [];
        }

        if ($node instanceof Expr\MethodCall) {
            $type = $scope->getType($node->var);
            $method = $node->name instanceof Node\Identifier ? strtolower($node->name->toString()) : '';
        } elseif ($node instanceof Expr\StaticCall && $node->class instanceof Node\Name) {
            $type = new ObjectType($scope->resolveName($node->class));
            $method = $node->name instanceof Node\Identifier ? strtolower($node->name->toString()) : '';
        } elseif ($node instanceof Expr\New_ && $node->class instanceof Node\Name) {
            $type = new ObjectType($scope->resolveName($node->class));
            $method = '__construct';
        } else {
            return [];
        }

        $controller = str_starts_with($owner, 'App\\Http\\Controllers\\');
        $request = str_starts_with($owner, 'App\\Http\\Requests\\');
        $model = new ObjectType(Model::class)->isSuperTypeOf(new ObjectType($owner))->yes()
            || str_starts_with($owner, 'App\\Models\\Eloquent\\')
            || str_starts_with($owner, 'App\\Models\\Concerns\\');
        $gateway = str_starts_with($owner, 'App\\Models\\Gateway\\');
        $orm = false;
        foreach ([Model::class, Builder::class, QueryBuilder::class, Relation::class] as $base) {
            $orm = $orm || new ObjectType($base)->isSuperTypeOf($type)->yes();
        }

        $reason = null;
        if (($controller || $request || $gateway) && $orm && in_array($method, self::WRITES, true)) {
            $reason = '永続化・状態変更は Eloquent Model の業務メソッドへ移す';
        }

        foreach ($type->getObjectClassNames() as $target) {
            $external = str_starts_with($target, 'Stripe\\')
                || str_starts_with($target, 'GuzzleHttp\\')
                || str_starts_with($target, 'Illuminate\\Http\\Client\\')
                || $target === Http::class
                || str_starts_with($target, 'Laravel\\Cashier\\');
            if (($controller || $request || $model) && $external) {
                $reason = '外部通信・SDK操作は Gateway へ移す';
            }

            if (($request || $model) && str_starts_with($target, 'App\\Models\\Gateway\\')) {
                $reason = 'Gateway との連携は Controller・Job または責務を限定した Support で行う';
            }

            if (($model || $gateway) && (
                $target === Request::class
                || str_starts_with($target, 'App\\Http\\')
                || in_array($target, [Response::class, RedirectResponse::class, Inertia::class], true)
            )) {
                $reason = 'HTTP入出力は Controller・Form Request へ移す';
            }

            if (($controller || $request || $gateway) && (
                $target === DB::class
                || str_starts_with($target, Connection::class)
            )) {
                $reason = 'DB操作・トランザクションは Eloquent Model または横断処理を担う Support へ移す';
            }

            if (($controller || $request) && (
                ($method === 'lock' && str_starts_with($target, 'Illuminate\\Cache\\'))
                || ($method === 'lock' && $target === Cache::class)
                || ($orm && in_array($method, ['lockforupdate', 'sharedlock', 'lock'], true))
            )) {
                $reason = '排他制御は状態変更を所有する Model または Support へ移す';
            }
        }

        if ($reason === null) {
            return [];
        }

        return [RuleErrorBuilder::message(sprintf('%s::%s(): %s。', $owner, $method, $reason))
            ->identifier('architecture.layerBoundary')->build()];
    }
}
