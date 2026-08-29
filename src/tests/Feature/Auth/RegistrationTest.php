<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class RegistrationTest extends TestCase
{
    use RefreshDatabase;

    public function test_registration_screen_can_be_rendered(): void
    {
        scenario('ユーザー登録画面を表示する')
            ->given('未認証のユーザー', fn () => null)
            ->when('ユーザー登録画面へアクセスする', fn () => $this->get('/register'))
            ->then('画面が正常に表示される', fn ($response) => $response->assertStatus(200))
            ->run();
    }

    public function test_new_users_can_register(): void
    {
        scenario('新規ユーザーを登録する')
            ->given('有効な登録情報', fn () => [
                'name' => 'Test User',
                'email' => 'test@example.com',
                'password' => 'password',
                'password_confirmation' => 'password',
            ])
            ->when('登録情報を送信する', fn (array $data) => $this->post('/register', $data))
            ->then('認証済みになる', function (): void {
                $this->assertAuthenticated();
            })
            ->and('ダッシュボードへリダイレクトされる', fn ($response) => $response->assertRedirect(route('dashboard', absolute: false)))
            ->run();
    }
}
