<?php

declare(strict_types=1);

namespace Tests\PHPStan\Rules;

use Illuminate\Http\Request;
use PhpParser\Node;
use PhpParser\Node\Expr\MethodCall;
use PHPStan\Analyser\Scope;
use PHPStan\Reflection\ClassReflection;
use PHPStan\Rules\IdentifierRuleError;
use PHPStan\Rules\Rule;
use PHPStan\Rules\RuleErrorBuilder;
use PHPStan\Type\ObjectType;

/**
 * .claude/rules/laravel/form-request-validation.md:
 * Controller で $request->validate() / request()->validate() を使わず、
 * ルールは Form Request の rules() に置く。
 *
 * Validator ファサードの参照禁止（Pest arch）だけではこれらの呼び出しを検出できない。
 * 変数名ではなくレシーバの「型」で判定するため、$req や $httpRequest のように
 * 別名を付けた場合も検出できる。
 *
 * @implements Rule<MethodCall>
 */
final class ControllerValidationRule implements Rule
{
    private const string CONTROLLER_NAMESPACE = 'App\\Http\\Controllers\\';

    /**
     * PHP のメソッド名は大文字小文字を区別しないため小文字で持つ。
     *
     * @var list<string>
     */
    private const array METHODS = ['validate', 'validatewithbag'];

    public function getNodeType(): string
    {
        return MethodCall::class;
    }

    /**
     * @return list<IdentifierRuleError>
     */
    public function processNode(Node $node, Scope $scope): array
    {
        if (! $node->name instanceof Node\Identifier) {
            return [];
        }

        $method = strtolower($node->name->toString());

        if (! in_array($method, self::METHODS, true)) {
            return [];
        }

        $class = $scope->getClassReflection();

        if (! $class instanceof ClassReflection || ! str_starts_with($class->getName(), self::CONTROLLER_NAMESPACE)) {
            return [];
        }

        // Auth::guard()->validate() のような別オブジェクトの validate は対象外。
        if (! (new ObjectType(Request::class))->isSuperTypeOf($scope->getType($node->var))->yes()) {
            return [];
        }

        return [
            RuleErrorBuilder::message(sprintf(
                'Controller は入力検証を Form Request に委ねる。%s() をやめ、ルールを app/Http/Requests/** の rules() に移し、$request->validated() で受け取る。',
                $node->name->toString(),
            ))
                ->identifier('laravel.controllerValidation')
                ->build(),
        ];
    }
}
