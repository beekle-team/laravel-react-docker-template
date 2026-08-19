<?php

declare(strict_types=1);

use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Foundation\Http\Middleware\HandlePrecognitiveRequests;
use Illuminate\Routing\Route;
use Illuminate\Support\Facades\Route as RouteFacade;

// .claude/rules/laravel/form-request-validation.md:
// Form Request を使う変更系 route には HandlePrecognitiveRequests を付ける。
// これが漏れるとフロントの validate() がライブ検証ではなく本処理を実行してしまう。

it('Form Request を使う変更系 route には Precognition middleware が付いている', function () {
    // controller action だけでなくクロージャ route も対象にする。
    $reflectAction = function (Route $route): ?ReflectionFunctionAbstract {
        $action = $route->getAction('uses');

        if ($action instanceof Closure) {
            return new ReflectionFunction($action);
        }

        $controller = $route->getControllerClass();

        if ($controller === null || ! class_exists($controller)) {
            return null;
        }

        try {
            return new ReflectionMethod($controller, $route->getActionMethod());
        } catch (ReflectionException) {
            return null;
        }
    };

    $usesFormRequest = function (Route $route) use ($reflectAction): bool {
        $method = $reflectAction($route);

        if ($method === null) {
            return false;
        }

        foreach ($method->getParameters() as $parameter) {
            $type = $parameter->getType();

            if (! $type instanceof ReflectionNamedType || $type->isBuiltin()) {
                continue;
            }

            if (is_subclass_of($type->getName(), FormRequest::class)) {
                return true;
            }
        }

        return false;
    };

    $writeMethods = ['POST', 'PUT', 'PATCH', 'DELETE'];
    $checked = 0;
    $missing = [];

    foreach (RouteFacade::getRoutes() as $route) {
        if (array_intersect($writeMethods, $route->methods()) === [] || ! $usesFormRequest($route)) {
            continue;
        }

        $checked++;

        if (! in_array(HandlePrecognitiveRequests::class, $route->gatherMiddleware(), true)) {
            $missing[] = implode('|', $route->methods()).' /'.$route->uri();
        }
    }

    expect($checked)->toBeGreaterThan(0)
        ->and($missing)->toBe([]);
});
