<?php

declare(strict_types=1);

namespace Tests\Support;

use FilesystemIterator;
use InvalidArgumentException;
use RecursiveDirectoryIterator;
use RecursiveIteratorIterator;
use ReflectionClass;
use SplFileInfo;

/**
 * 自分たちのファイルで宣言された旧来のローカルスコープ（scopeXxx）を見つける。
 */
final class LocalScopeNaming
{
    /**
     * @return list<string>
     */
    public static function violations(string $root): array
    {
        $resolvedRoot = realpath($root);
        if ($resolvedRoot === false) {
            throw new InvalidArgumentException('Scope scan root does not exist: '.$root);
        }

        $violations = [];
        $iterator = new RecursiveIteratorIterator(
            new RecursiveDirectoryIterator($resolvedRoot, FilesystemIterator::SKIP_DOTS),
        );

        foreach ($iterator as $file) {
            if (! $file instanceof SplFileInfo || $file->getExtension() !== 'php') {
                continue;
            }

            $class = self::typeName($file->getPathname());
            if ($class === null || (! class_exists($class) && ! trait_exists($class))) {
                continue;
            }

            foreach (new ReflectionClass($class)->getMethods() as $method) {
                // getDeclaringClass() は use した側を返す。宣言ファイルで依存パッケージを外す。
                $declaredFile = $method->getFileName();
                $resolvedFile = is_string($declaredFile) ? realpath($declaredFile) : false;
                $declaredHere = is_string($resolvedFile)
                    && str_starts_with($resolvedFile, $resolvedRoot.DIRECTORY_SEPARATOR);

                // 呼び出し側はどちらの書き方でも同じなので、混在しても動いてしまう。名前で止める。
                if ($declaredHere && str_starts_with($method->getName(), 'scope')) {
                    $violations[] = $class.'::'.$method->getName();
                }
            }
        }

        $violations = array_values(array_unique($violations));
        sort($violations);

        return $violations;
    }

    private static function typeName(string $path): ?string
    {
        $code = file_get_contents($path);
        if ($code === false || ! preg_match('/^namespace\s+([^;]+);/m', $code, $namespace)) {
            return null;
        }

        if (! preg_match('/\b(?:class|trait)\s+([A-Za-z_][A-Za-z0-9_]*)/m', $code, $type)) {
            return null;
        }

        return $namespace[1].'\\'.$type[1];
    }
}
