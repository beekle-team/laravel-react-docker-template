<?php

declare(strict_types=1);

namespace App\Models\Eloquent\ArchitectureFixture;

use Illuminate\Database\Eloquent\Attributes\Scope as LocalScope;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Collection;

final class ScopedRecord extends Model
{
    /** @param Builder<self> $query */
    public function scopePending(Builder $query): void
    {
        $query->where('status', 'pending');
        $query->get();
        auth();
    }

    /** @param Builder<self> $query */
    #[LocalScope]
    protected function visible(Builder $query): void
    {
        $query->first();
        request();
        $query->update([]);
    }

    /** @param Builder<self> $query */
    #[LocalScope]
    protected function forOwner(Builder $query, int $ownerId): void
    {
        $query->where('owner_id', $ownerId)->orderBy('id');
        $options = new Collection(['status' => 'pending']);
        $query->where('status', $options->get('status'));
    }

    /** @param Builder<self> $query */
    public function outsideScope(Builder $query): void
    {
        $query->first();
    }
}
