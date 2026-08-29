<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Eloquent\User;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Notification;
use LogicException;
use Tests\TestCase;

final class PasswordResetTest extends TestCase
{
    use RefreshDatabase;

    public function test_reset_password_link_screen_can_be_rendered(): void
    {
        scenario('パスワード再設定リンク画面を表示する')
            ->given('未認証のユーザー', fn () => null)
            ->when('パスワード再設定リンク画面へアクセスする', fn () => $this->get('/forgot-password'))
            ->then('画面が正常に表示される', fn ($response) => $response->assertStatus(200))
            ->run();
    }

    public function test_reset_password_link_can_be_requested(): void
    {
        scenario('パスワード再設定リンクを要求する')
            ->given('登録済みユーザー', function (): User {
                Notification::fake();

                return User::factory()->create();
            })
            ->when('登録メールアドレスを送信する', fn (User $user) => $this->post('/forgot-password', [
                'email' => $user->email,
            ]))
            ->then('再設定通知が送信される', fn ($response, User $user) => Notification::assertSentTo($user, ResetPassword::class))
            ->run();
    }

    public function test_reset_password_screen_can_be_rendered(): void
    {
        scenario('有効なトークンでパスワード再設定画面を表示する')
            ->given('再設定通知を受け取った登録済みユーザー', fn () => $this->requestPasswordReset())
            ->when('再設定URLへアクセスする', fn (array $context) => $this->get('/reset-password/'.$context['token']))
            ->then('画面が正常に表示される', fn ($response) => $response->assertStatus(200))
            ->run();
    }

    public function test_password_can_be_reset_with_valid_token(): void
    {
        scenario('有効なトークンでパスワードを再設定する')
            ->given('再設定通知を受け取った登録済みユーザー', fn () => $this->requestPasswordReset())
            ->when('新しいパスワードを送信する', fn (array $context) => $this->post('/reset-password', [
                'token' => $context['token'],
                'email' => $context['user']->email,
                'password' => 'password',
                'password_confirmation' => 'password',
            ]))
            ->then('セッションエラーがない', fn ($response) => $response->assertSessionHasNoErrors())
            ->and('ログイン画面へリダイレクトされる', fn ($response) => $response->assertRedirect(route('login')))
            ->run();
    }

    /** @return array{user: User, token: string} */
    private function requestPasswordReset(): array
    {
        Notification::fake();

        $user = User::factory()->create();
        $this->post('/forgot-password', ['email' => $user->email]);

        $notification = Notification::sent($user, ResetPassword::class)->first();

        if (! $notification instanceof ResetPassword) {
            throw new LogicException('パスワード再設定通知が送信されませんでした。');
        }

        return [
            'user' => $user,
            'token' => $notification->token,
        ];
    }
}
