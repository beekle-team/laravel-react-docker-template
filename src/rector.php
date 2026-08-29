<?php

declare(strict_types=1);

use Rector\Config\RectorConfig;
use Rector\Php54\Rector\Array_\LongArrayToShortArrayRector;
use Rector\TypeDeclaration\Rector\ArrowFunction\AddArrowFunctionReturnTypeRector;
use Rector\ValueObject\PhpVersion;
use RectorLaravel\Set\LaravelSetProvider;

return RectorConfig::configure()
    ->withPaths([
        __DIR__.'/app',
        __DIR__.'/bootstrap',
        __DIR__.'/config',
        __DIR__.'/database',
        __DIR__.'/public/index.php',
        __DIR__.'/routes',
        __DIR__.'/tests',
    ])
    ->withSkip([
        __DIR__.'/bootstrap/cache',
        __DIR__.'/storage',
        __DIR__.'/vendor',
        // Pint が array() → [] を扱う。Rector と二重適用しない。
        LongArrayToShortArrayRector::class,
        // GWT の fn () => expect(...) に Pest 内部型 (\Pest\Mixins\Expectation) を
        // 書かせても読みづらいだけなので、テストだけ除外する。
        AddArrowFunctionReturnTypeRector::class => [
            __DIR__.'/tests',
        ],
    ])
    // 実行環境・Composer・CIをPHP 8.5へ統一する。
    ->withPhpSets(php85: true)
    ->withPhpVersion(PhpVersion::PHP_85)
    // バージョン移行セットだけでは死蔵コード・型宣言漏れを拾えないので、
    // 品質セットも有効にする（CI の rector --dry-run がこれで効く）。
    ->withPreparedSets(
        deadCode: true,
        codeQuality: true,
        typeDeclarations: true,
        earlyReturn: true,
        instanceOf: true,
        phpunitCodeQuality: true,
    )
    ->withSetProviders(LaravelSetProvider::class)
    ->withComposerBased(laravel: true);
