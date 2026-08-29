<?php

declare(strict_types=1);

namespace App\Http\Controllers;

use App\Models\Eloquent\User;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Request;

abstract class Controller
{
    /**
     * auth middleware 配下の route では認証済みが保証されるが、
     * Request::user() の戻り型は null 許容のままなので一度だけここで絞り込む。
     *
     * @throws AuthenticationException
     */
    protected function authenticatedUser(Request $request): User
    {
        $user = $request->user();

        if (! $user instanceof User) {
            throw new AuthenticationException;
        }

        return $user;
    }
}
