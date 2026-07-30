<?php

declare(strict_types=1);

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

/**
 * 認証機能 - GWT テスト
 *
 * @see .kiro/specs/auth/requirements.md
 */

// =============================================================================
// UC-01: ユーザー登録
// =============================================================================

describe('UC-01: ユーザー登録', function () {
    it('Scenario 1.1: 有効なデータで新規ユーザーを登録できる', function () {
        scenario('新規ユーザー登録フロー')
            ->given('有効なユーザーデータ（名前、メール、パスワード）', function () {
                return [
                    'name' => 'Test User',
                    'email' => 'test@example.com',
                    'password' => 'password',
                    'password_confirmation' => 'password',
                ];
            })
            ->when('登録APIを呼び出す', function (array $userData) {
                return $this->post('/register', $userData);
            })
            ->then('ユーザーが作成される', function ($response) {
                expect(User::where('email', 'test@example.com')->exists())->toBeTrue();
            })
            ->and('認証済み状態になる', function ($response) {
                $this->assertAuthenticated();
            })
            ->and('ダッシュボードにリダイレクトされる', function ($response) {
                $response->assertRedirect(route('dashboard', absolute: false));
            })
            ->run();
    });

    it('Scenario 1.2: 重複メールアドレスでは登録できない', function () {
        scenario('重複メール登録エラー')
            ->given('既存ユーザーと同じメールアドレス', function () {
                $existingUser = User::factory()->create(['email' => 'existing@example.com']);

                return [
                    'name' => 'New User',
                    'email' => 'existing@example.com',
                    'password' => 'password',
                    'password_confirmation' => 'password',
                ];
            })
            ->when('登録APIを呼び出す', function (array $userData) {
                return $this->post('/register', $userData);
            })
            ->then('バリデーションエラーになる', function ($response) {
                $response->assertSessionHasErrors('email');
            })
            ->and('emailフィールドにエラーが表示される', function ($response) {
                $response->assertInvalid(['email']);
            })
            ->run();
    });
});

// =============================================================================
// UC-02: ログイン
// =============================================================================

describe('UC-02: ログイン', function () {
    it('Scenario 2.1: 正しい認証情報でログインできる', function () {
        scenario('正常ログインフロー')
            ->given('登録済みユーザーが存在する', function () {
                return User::factory()->create([
                    'email' => 'user@example.com',
                    'password' => bcrypt('correct-password'),
                ]);
            })
            ->and('正しいメールアドレスとパスワード', function (User $user) {
                return [
                    'user' => $user,
                    'credentials' => [
                        'email' => 'user@example.com',
                        'password' => 'correct-password',
                    ],
                ];
            })
            ->when('ログインAPIを呼び出す', function (array $context) {
                return $this->post('/login', $context['credentials']);
            })
            ->then('認証済み状態になる', function ($response) {
                $this->assertAuthenticated();
            })
            ->and('セッションが開始される', function ($response) {
                $response->assertSessionHasNoErrors();
            })
            ->run();
    });

    it('Scenario 2.2: 間違ったパスワードではログインできない', function () {
        scenario('パスワード誤りでログイン失敗')
            ->given('登録済みユーザーが存在する', function () {
                return User::factory()->create([
                    'email' => 'user@example.com',
                    'password' => bcrypt('correct-password'),
                ]);
            })
            ->and('間違ったパスワード', function (User $user) {
                return [
                    'user' => $user,
                    'credentials' => [
                        'email' => 'user@example.com',
                        'password' => 'wrong-password',
                    ],
                ];
            })
            ->when('ログインAPIを呼び出す', function (array $context) {
                return $this->post('/login', $context['credentials']);
            })
            ->then('ゲスト状態のまま', function ($response) {
                $this->assertGuest();
            })
            ->and('認証エラーが返される', function ($response) {
                $response->assertSessionHasErrors('email');
            })
            ->run();
    });
});

// =============================================================================
// UC-03: ログアウト
// =============================================================================

describe('UC-03: ログアウト', function () {
    it('Scenario 3.1: ログアウトできる', function () {
        scenario('ログアウトフロー')
            ->given('ログイン済みユーザー', function () {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('ログアウトAPIを呼び出す', function (User $user) {
                return $this->post('/logout');
            })
            ->then('ゲスト状態になる', function ($response) {
                $this->assertGuest();
            })
            ->and('セッションが破棄される', function ($response) {
                $response->assertRedirect('/');
            })
            ->run();
    });
});
