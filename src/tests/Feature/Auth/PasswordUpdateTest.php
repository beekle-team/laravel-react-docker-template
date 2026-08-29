<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

final class PasswordUpdateTest extends TestCase
{
    use RefreshDatabase;

    public function test_password_can_be_updated(): void
    {
        scenario('正しい現在のパスワードで更新する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('新しいパスワードを送信する', fn () => $this->from('/profile')->put('/password', [
                'current_password' => 'password',
                'password' => 'new-password',
                'password_confirmation' => 'new-password',
            ]))
            ->then('セッションエラーがない', fn ($response) => $response->assertSessionHasNoErrors())
            ->and('プロフィール画面へリダイレクトされる', fn ($response) => $response->assertRedirect('/profile'))
            ->and('新しいパスワードが保存される', function ($response, User $user): void {
                $this->assertTrue(Hash::check('new-password', $user->refresh()->password));
            })
            ->run();
    }

    public function test_correct_password_must_be_provided_to_update_password(): void
    {
        scenario('誤った現在のパスワードで更新する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('誤った現在のパスワードを送信する', fn () => $this->from('/profile')->put('/password', [
                'current_password' => 'wrong-password',
                'password' => 'new-password',
                'password_confirmation' => 'new-password',
            ]))
            ->then('現在のパスワードにエラーがある', fn ($response) => $response->assertSessionHasErrors('current_password'))
            ->and('プロフィール画面へ戻る', fn ($response) => $response->assertRedirect('/profile'))
            ->run();
    }
}
