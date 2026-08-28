<?php

declare(strict_types=1);

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Validator;

// .claude/rules/laravel/model-layer-boundaries.md を実行可能な形にした検査。

it('Service / Action レイヤーを作らない', function (): void {
    expect(is_dir(app_path('Services')))->toBeFalse()
        ->and(is_dir(app_path('Actions')))->toBeFalse();
});

arch('Service 接尾辞のクラスを作らない')
    ->expect('App')
    ->not->toHaveSuffix('Service');

arch('Eloquent Model は Eloquent の Model を継承する')
    ->expect('App\Models\Eloquent')
    ->toExtend(Model::class);

arch('Eloquent Model から外部 API を呼ばない')
    ->expect('App\Models\Eloquent')
    ->not->toUse(Http::class);

arch('Gateway Model は Gateway の基底クラスを継承する')
    ->expect('App\Models\Gateway')
    ->classes()
    ->toExtend(App\Models\Gateway\Model::class)
    ->ignoring(App\Models\Gateway\Model::class);

arch('Gateway Model は DB 永続化しない')
    ->expect('App\Models\Gateway')
    ->not->toUse([Model::class, DB::class]);

arch('Concerns は Trait として書く')
    ->expect('App\Models\Concerns')
    ->toBeTraits();

// .claude/rules/laravel/form-request-validation.md の Controller 側ルール。

arch('Controller は入力検証を Form Request に委ねる')
    ->expect('App\Http\Controllers')
    ->not->toUse(Validator::class);

arch('Controller から DB ファサードを直接使わない')
    ->expect('App\Http\Controllers')
    ->not->toUse(DB::class);
