<?php

declare(strict_types=1);

namespace App\Providers;

use Carbon\Carbon;
use Carbon\CarbonImmutable;
use Carbon\CarbonInterface;
use DateTime;
use DateTimeImmutable;
use Spatie\LaravelTypeScriptTransformer\LaravelData\LaravelDataTypeScriptTransformerExtension;
use Spatie\LaravelTypeScriptTransformer\TypeScriptTransformerApplicationServiceProvider;
use Spatie\TypeScriptTransformer\Transformers\AttributedClassTransformer;
use Spatie\TypeScriptTransformer\Transformers\EnumTransformer;
use Spatie\TypeScriptTransformer\TypeScriptTransformerConfigFactory;
use Spatie\TypeScriptTransformer\Writers\GlobalNamespaceWriter;

final class TypeScriptTransformerServiceProvider extends TypeScriptTransformerApplicationServiceProvider
{
    protected function configure(TypeScriptTransformerConfigFactory $config): void
    {
        $config
            ->transformer(AttributedClassTransformer::class)
            ->transformer(EnumTransformer::class)
            ->extension(new LaravelDataTypeScriptTransformerExtension)
            ->transformDirectories(app_path())
            ->outputDirectory(resource_path('js/types'))
            ->writer(new GlobalNamespaceWriter('generated.d.ts'))
            ->replaceType(DateTime::class, 'string')
            ->replaceType(DateTimeImmutable::class, 'string')
            ->replaceType(CarbonInterface::class, 'string')
            ->replaceType(CarbonImmutable::class, 'string')
            ->replaceType(Carbon::class, 'string')
            ->withoutManifest();
    }
}
