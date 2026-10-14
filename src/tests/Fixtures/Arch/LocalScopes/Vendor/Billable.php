<?php

declare(strict_types=1);

namespace Tests\Fixtures\Arch\LocalScopes\Vendor;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

trait Billable
{
    /**
     * @param  Builder<Model>  $query
     * @return Builder<Model>
     */
    public function scopeOnGenericTrial(Builder $query): Builder
    {
        return $query->whereNull('trial_ends_at');
    }
}
