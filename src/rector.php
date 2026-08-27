<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Php54\Rector\Array_\LongArrayToShortArrayRector;
use Rector\ValueObject\PhpVersion;
use RectorLaravel\Set\LaravelSetProvider;

return RectorConfig::configure()
    ->withPaths([
        __DIR__.'/app',
        __DIR__.'/bootstrap/app.php',
        __DIR__.'/config',
        __DIR__.'/database',
        __DIR__.'/routes',
        __DIR__.'/tests',
    ])
    ->withSkip([
        __DIR__.'/bootstrap/cache',
        __DIR__.'/storage',
        __DIR__.'/vendor',
        // Pint が array() → [] を扱う。Rector と二重適用しない。
        LongArrayToShortArrayRector::class,
    ])
    // composer / Laravel 13 の下限は PHP 8.3。Docker / CI 本命の 8.5 専用構文は入れない。
    ->withPhpSets(php83: true)
    ->withPhpVersion(PhpVersion::PHP_83)
    ->withSetProviders(LaravelSetProvider::class)
    ->withComposerBased(laravel: true);
