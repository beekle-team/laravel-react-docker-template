<?php

declare(strict_types=1);

namespace App\Http\Requests\Auth;

use App\Models\Eloquent\User;
use Illuminate\Contracts\Validation\ValidationRule;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rules;

class RegisterUserRequest extends FormRequest
{
    /**
     * Get the validation rules that apply to the request.
     *
     * @return array<string, ValidationRule|array<mixed>|string>
     */
    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'email' => 'required|string|lowercase|email|max:255|unique:'.User::class,
            'password' => ['required', 'confirmed', Rules\Password::defaults()],
        ];
    }

    /**
     * バリデーション済みのパスワード。validated() は mixed を返すため型付きで公開する。
     */
    public function password(): string
    {
        return $this->string('password')->value();
    }
}
