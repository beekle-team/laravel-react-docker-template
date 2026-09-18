<?php

declare(strict_types=1);

namespace App\Http\Controllers\ArchitectureFixture;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\Client\Factory;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;

final class ExampleController
{
    public function run(Model $record, Factory $http, DomainOperation $operation): void
    {
        $record->save();
        $record?->delete();
        DB::transaction(fn () => null);
        Cache::lock('example');
        Http::get('https://example.test');
        $http->post('https://example.test');
        $record->newQuery()->where('status', 'pending')->first();
        $operation->save();
    }
}

final class DomainOperation
{
    public function save(): void {}
}

namespace App\Models\Gateway\ArchitectureFixture;

use Illuminate\Database\Eloquent\Model;

final class ExampleGateway
{
    public function run(Model $record): void
    {
        $record->update([]);
    }
}

namespace App\Models\Eloquent\ArchitectureFixture;

use Illuminate\Support\Facades\Http;

final class ExampleModel
{
    public function run(): void
    {
        Http::get('https://example.test');
    }
}
