<?php

declare(strict_types=1);

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;

uses(RefreshDatabase::class);

/**
 * 認証機能 BDD テスト
 *
 * @see .kiro/specs/auth/requirements.md
 */
describe('UC-01: ユーザー登録', function (): void {
    it('Scenario 1.1: 新規ユーザーを登録できる', function (): void {
        scenario('新規ユーザー登録')
            ->given('有効なユーザーデータ', fn () => [
                'name' => 'テストユーザー',
                'email' => 'test@example.com',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ])
            ->when('登録APIを呼び出す', fn (array $data) => $this->post('/register', $data))
            ->then('認証済みになる', fn () => $this->assertAuthenticated())
            ->and('ダッシュボードにリダイレクトされる', fn ($response) => $response->assertRedirect(route('dashboard', absolute: false)))
            ->run();
    });

    it('Scenario 1.2: 重複メールアドレスでは登録できない', function (): void {
        scenario('重複メールでの登録失敗')
            ->given('既存ユーザーと同じメールアドレス', fn () => User::factory()->create(['email' => 'existing@example.com']))
            ->and('登録データを準備', fn () => [
                'name' => '新規ユーザー',
                'email' => 'existing@example.com',
                'password' => 'password123',
                'password_confirmation' => 'password123',
            ])
            ->when('登録APIを呼び出す', fn (array $data) => $this->post('/register', $data))
            ->then('バリデーションエラーになる', fn ($response) => $response->assertSessionHasErrors(['email']))
            ->run();
    });
});

describe('UC-02: ログイン', function (): void {
    it('Scenario 2.1: 正しい認証情報でログインできる', function (): void {
        scenario('正常ログイン')
            ->given('登録済みユーザーが存在する', fn () => User::factory()->create([
                'email' => 'user@example.com',
                'password' => bcrypt('correct-password'),
            ]))
            ->and('正しいメールアドレスとパスワード', fn () => [
                'email' => 'user@example.com',
                'password' => 'correct-password',
            ])
            ->when('ログインAPIを呼び出す', fn (array $data) => $this->post('/login', $data))
            ->then('認証済み状態になる', fn () => $this->assertAuthenticated())
            ->run();
    });

    it('Scenario 2.2: 間違ったパスワードではログインできない', function (): void {
        scenario('パスワード間違いでログイン失敗')
            ->given('登録済みユーザーが存在する', fn () => User::factory()->create([
                'email' => 'user@example.com',
                'password' => bcrypt('correct-password'),
            ]))
            ->and('間違ったパスワード', fn () => [
                'email' => 'user@example.com',
                'password' => 'wrong-password',
            ])
            ->when('ログインAPIを呼び出す', fn (array $data) => $this->post('/login', $data))
            ->then('ゲスト状態のまま', fn () => $this->assertGuest())
            ->run();
    });
});

describe('UC-03: ログアウト', function (): void {
    it('Scenario 3.1: ログアウトできる', function (): void {
        scenario('ログアウト')
            ->given('ログイン済みユーザー', function () {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('ログアウトAPIを呼び出す', fn () => $this->post('/logout'))
            ->then('ゲスト状態になる', fn () => $this->assertGuest())
            ->run();
    });
});
