<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class PasswordConfirmationTest extends TestCase
{
    use RefreshDatabase;

    public function test_confirm_password_screen_can_be_rendered(): void
    {
        scenario('パスワード確認画面を表示する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('パスワード確認画面へアクセスする', fn () => $this->get('/confirm-password'))
            ->then('画面が正常に表示される', fn ($response) => $response->assertStatus(200))
            ->run();
    }

    public function test_password_can_be_confirmed(): void
    {
        scenario('正しいパスワードを確認する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('正しいパスワードを送信する', fn () => $this->post('/confirm-password', [
                'password' => 'password',
            ]))
            ->then('リダイレクトされる', fn ($response) => $response->assertRedirect())
            ->and('セッションエラーがない', fn ($response) => $response->assertSessionHasNoErrors())
            ->run();
    }

    public function test_password_is_not_confirmed_with_invalid_password(): void
    {
        scenario('誤ったパスワードを確認する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('誤ったパスワードを送信する', fn () => $this->post('/confirm-password', [
                'password' => 'wrong-password',
            ]))
            ->then('セッションエラーになる', fn ($response) => $response->assertSessionHasErrors())
            ->run();
    }
}
