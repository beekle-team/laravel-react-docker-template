<?php

declare(strict_types=1);

namespace App\Actions\Auth;

use App\Data\Auth\LoginData;
use Illuminate\Auth\Events\Lockout;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;

class LoginAction
{
    /**
     * Attempt to authenticate the request's credentials.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    public function execute(LoginData $data, string $ip): void
    {
        $this->ensureIsNotRateLimited($data, $ip);

        if (! Auth::attempt(['email' => $data->email, 'password' => $data->password], $data->remember)) {
            RateLimiter::hit($this->throttleKey($data, $ip));

            throw ValidationException::withMessages([
                'email' => trans('auth.failed'),
            ]);
        }

        RateLimiter::clear($this->throttleKey($data, $ip));
    }

    /**
     * Ensure the login request is not rate limited.
     *
     * @throws \Illuminate\Validation\ValidationException
     */
    protected function ensureIsNotRateLimited(LoginData $data, string $ip): void
    {
        if (! RateLimiter::tooManyAttempts($this->throttleKey($data, $ip), 5)) {
            return;
        }

        // event(new Lockout($request)); // RequestオブジェクトがないのでLockoutイベントの発火は少し工夫が必要だが、一旦省略またはDataを持たせる
        // LockoutイベントはRequestを要求するが、必須ではない場合も。
        // 正しくは new Lockout(request()) を使うか、イベントを自作するか。
        // ここではシンプルに request() ヘルパーを使う。
        event(new Lockout(request()));

        $seconds = RateLimiter::availableIn($this->throttleKey($data, $ip));

        throw ValidationException::withMessages([
            'email' => trans('auth.throttle', [
                'seconds' => $seconds,
                'minutes' => ceil($seconds / 60),
            ]),
        ]);
    }

    /**
     * Get the rate limiting throttle key for the request.
     */
    protected function throttleKey(LoginData $data, string $ip): string
    {
        return Str::transliterate(Str::lower($data->email).'|'.$ip);
    }
}
