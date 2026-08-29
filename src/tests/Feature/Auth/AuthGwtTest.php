<?php

declare(strict_types=1);

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

/**
 * 認証機能 - GWT テスト
 *
 * @see docs/specs/auth/requirements.md
 */

// =============================================================================
// UC-01: ユーザー登録
// =============================================================================

describe('UC-01: ユーザー登録', function (): void {
    it('Scenario 1.1: 有効なデータで新規ユーザーを登録できる', function (): void {
        scenario('新規ユーザー登録フロー')
            ->given('有効なユーザーデータ（名前、メール、パスワード）', fn () => [
                'name' => 'Test User',
                'email' => 'test@example.com',
                'password' => 'password',
                'password_confirmation' => 'password',
            ])
            ->when('登録APIを呼び出す', fn (array $userData) => $this->post('/register', $userData))
            ->then('ユーザーが作成される', function ($response): void {
                expect(User::where('email', 'test@example.com')->exists())->toBeTrue();
            })
            ->and('認証済み状態になる', function ($response): void {
                $this->assertAuthenticated();
            })
            ->and('ダッシュボードにリダイレクトされる', function ($response): void {
                $response->assertRedirect(route('dashboard', absolute: false));
            })
            ->run();
    });

    it('Scenario 1.2: 重複メールアドレスでは登録できない', function (): void {
        scenario('重複メール登録エラー')
            ->given('既存ユーザーと同じメールアドレス', function (): array {
                $existingUser = User::factory()->create(['email' => 'existing@example.com']);

                return [
                    'name' => 'New User',
                    'email' => 'existing@example.com',
                    'password' => 'password',
                    'password_confirmation' => 'password',
                ];
            })
            ->when('登録APIを呼び出す', fn (array $userData) => $this->post('/register', $userData))
            ->then('バリデーションエラーになる', function ($response): void {
                $response->assertSessionHasErrors('email');
            })
            ->and('emailフィールドにエラーが表示される', function ($response): void {
                $response->assertInvalid(['email']);
            })
            ->run();
    });
});

// =============================================================================
// UC-02: ログイン
// =============================================================================

describe('UC-02: ログイン', function (): void {
    it('Scenario 2.1: 正しい認証情報でログインできる', function (): void {
        scenario('正常ログインフロー')
            ->given('登録済みユーザーが存在する', fn () => User::factory()->create([
                'email' => 'user@example.com',
                'password' => bcrypt('correct-password'),
            ]))
            ->and('正しいメールアドレスとパスワード', fn (User $user) => [
                'user' => $user,
                'credentials' => [
                    'email' => 'user@example.com',
                    'password' => 'correct-password',
                ],
            ])
            ->when('ログインAPIを呼び出す', fn (array $context) => $this->post('/login', $context['credentials']))
            ->then('認証済み状態になる', function ($response): void {
                $this->assertAuthenticated();
            })
            ->and('セッションが開始される', function ($response): void {
                $response->assertSessionHasNoErrors();
            })
            ->run();
    });

    it('Scenario 2.2: 間違ったパスワードではログインできない', function (): void {
        scenario('パスワード誤りでログイン失敗')
            ->given('登録済みユーザーが存在する', fn () => User::factory()->create([
                'email' => 'user@example.com',
                'password' => bcrypt('correct-password'),
            ]))
            ->and('間違ったパスワード', fn (User $user) => [
                'user' => $user,
                'credentials' => [
                    'email' => 'user@example.com',
                    'password' => 'wrong-password',
                ],
            ])
            ->when('ログインAPIを呼び出す', fn (array $context) => $this->post('/login', $context['credentials']))
            ->then('ゲスト状態のまま', function ($response): void {
                $this->assertGuest();
            })
            ->and('認証エラーが返される', function ($response): void {
                $response->assertSessionHasErrors('email');
            })
            ->run();
    });
});

// =============================================================================
// UC-03: ログアウト
// =============================================================================

describe('UC-03: ログアウト', function (): void {
    it('Scenario 3.1: ログアウトできる', function (): void {
        scenario('ログアウトフロー')
            ->given('ログイン済みユーザー', function () {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('ログアウトAPIを呼び出す', fn (User $user) => $this->post('/logout'))
            ->then('ゲスト状態になる', function ($response): void {
                $this->assertGuest();
            })
            ->and('セッションが破棄される', function ($response): void {
                $response->assertRedirect('/');
            })
            ->run();
    });
});
