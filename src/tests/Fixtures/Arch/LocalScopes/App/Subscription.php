<?php

declare(strict_types=1);

namespace Tests\Fixtures\Arch\LocalScopes\App;

use Illuminate\Database\Eloquent\Model;
use Tests\Fixtures\Arch\LocalScopes\Vendor\Billable;

class Subscription extends Model
{
    use Billable;
}
