<?php

declare(strict_types=1);

arch()->preset()->php();

arch()->preset()->security();

// App\Models\Gateway は DB 永続化しない外部接続レイヤーなので、
// Eloquent Model 前提の Laravel preset の検査対象から外す。
arch()->preset()->laravel()->ignoring('App\Models\Gateway');
