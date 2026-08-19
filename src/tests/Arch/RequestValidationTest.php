<?php

declare(strict_types=1);

// .claude/rules/laravel/form-request-validation.md:
// Controller で $request->validate() / request()->validate() を使わず、
// ルールは Form Request の rules() に置く。Validator ファサードの参照禁止だけでは
// これらの呼び出しを検出できないため、トークン列から直接見つける。

/**
 * @return list<string>
 */
function controllerSources(): array
{
    $directory = new RecursiveDirectoryIterator(app_path('Http/Controllers'));
    $files = [];

    foreach (new RecursiveIteratorIterator($directory) as $file) {
        if ($file->isFile() && $file->getExtension() === 'php') {
            $files[] = $file->getPathname();
        }
    }

    return $files;
}

/**
 * `$request->validate(...)` と `request()->validate(...)` を検出する。
 * コメントや文字列リテラルを除いたトークン列で判定するため、
 * `Auth::guard()->validate(...)` のような別オブジェクトの validate は対象外。
 *
 * @return list<string>
 */
function validateCallsIn(string $code): array
{
    $accessors = [T_OBJECT_OPERATOR, T_NULLSAFE_OBJECT_OPERATOR];
    $methods = ['validate', 'validateWithBag'];
    $ignored = [T_WHITESPACE, T_COMMENT, T_DOC_COMMENT, T_CONSTANT_ENCAPSED_STRING];

    $tokens = array_values(array_filter(
        token_get_all($code),
        fn (array|string $token): bool => is_string($token) || ! in_array($token[0], $ignored, true),
    ));

    $found = [];

    foreach ($tokens as $index => $token) {
        if (! is_array($token) || ! in_array($token[0], $accessors, true)) {
            continue;
        }

        $method = $tokens[$index + 1] ?? null;

        if (! is_array($method) || $method[0] !== T_STRING || ! in_array($method[1], $methods, true)) {
            continue;
        }

        $previous = $tokens[$index - 1] ?? null;

        // $request->validate(...)
        if (is_array($previous) && $previous[0] === T_VARIABLE && $previous[1] === '$request') {
            $found[] = '$request->'.$method[1].'()';

            continue;
        }

        // request()->validate(...)
        $helper = $tokens[$index - 3] ?? null;

        if (
            $previous === ')'
            && ($tokens[$index - 2] ?? null) === '('
            && is_array($helper)
            && $helper[0] === T_STRING
            && $helper[1] === 'request'
        ) {
            $found[] = 'request()->'.$method[1].'()';
        }
    }

    return $found;
}

it('Controller で $request->validate() を使わない', function () {
    $violations = [];

    foreach (controllerSources() as $file) {
        foreach (validateCallsIn((string) file_get_contents($file)) as $call) {
            $violations[] = basename($file).': '.$call;
        }
    }

    expect($violations)->toBe([]);
});
