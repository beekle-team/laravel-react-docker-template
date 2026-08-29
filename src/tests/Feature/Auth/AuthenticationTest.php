<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class AuthenticationTest extends TestCase
{
    use RefreshDatabase;

    public function test_login_screen_can_be_rendered(): void
    {
        scenario('ログイン画面を表示する')
            ->given('未認証のユーザー', fn () => null)
            ->when('ログイン画面へアクセスする', fn () => $this->get('/login'))
            ->then('画面が正常に表示される', fn ($response) => $response->assertStatus(200))
            ->run();
    }

    public function test_users_can_authenticate_using_the_login_screen(): void
    {
        scenario('正しい認証情報でログインする')
            ->given('登録済みユーザー', fn () => User::factory()->create())
            ->when('正しい認証情報を送信する', fn (User $user) => $this->post('/login', [
                'email' => $user->email,
                'password' => 'password',
            ]))
            ->then('認証済みになる', function (): void {
                $this->assertAuthenticated();
            })
            ->and('ダッシュボードへリダイレクトされる', fn ($response) => $response->assertRedirect(route('dashboard', absolute: false)))
            ->run();
    }

    public function test_users_can_not_authenticate_with_invalid_password(): void
    {
        scenario('誤ったパスワードでログインする')
            ->given('登録済みユーザー', fn () => User::factory()->create())
            ->when('誤ったパスワードを送信する', fn (User $user) => $this->post('/login', [
                'email' => $user->email,
                'password' => 'wrong-password',
            ]))
            ->then('ゲスト状態のままになる', function (): void {
                $this->assertGuest();
            })
            ->run();
    }

    public function test_users_can_logout(): void
    {
        scenario('ログアウトする')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('ログアウトを送信する', fn () => $this->post('/logout'))
            ->then('ゲスト状態になる', function (): void {
                $this->assertGuest();
            })
            ->and('トップページへリダイレクトされる', fn ($response) => $response->assertRedirect('/'))
            ->run();
    }
}
