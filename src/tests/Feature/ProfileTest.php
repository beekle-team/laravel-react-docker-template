<?php

declare(strict_types=1);

namespace Tests\Feature;

use App\Models\Eloquent\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ProfileTest extends TestCase
{
    use RefreshDatabase;

    public function test_profile_page_is_displayed(): void
    {
        scenario('プロフィール画面を表示する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('プロフィール画面へアクセスする', fn () => $this->get('/profile'))
            ->then('画面が正常に表示される', fn ($response) => $response->assertOk())
            ->run();
    }

    public function test_profile_information_can_be_updated(): void
    {
        scenario('プロフィール情報を更新する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('新しいプロフィール情報を送信する', fn () => $this->patch('/profile', [
                'name' => 'Test User',
                'email' => 'test@example.com',
            ]))
            ->then('セッションエラーがない', fn ($response) => $response->assertSessionHasNoErrors())
            ->and('プロフィール画面へリダイレクトされる', fn ($response) => $response->assertRedirect('/profile'))
            ->and('プロフィール情報が保存される', function ($response, User $user): void {
                $user->refresh();

                $this->assertSame('Test User', $user->name);
                $this->assertSame('test@example.com', $user->email);
                $this->assertNull($user->email_verified_at);
            })
            ->run();
    }

    public function test_email_verification_status_is_unchanged_when_the_email_address_is_unchanged(): void
    {
        scenario('メールアドレスを変えずにプロフィールを更新する')
            ->given('メール確認済みのログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('同じメールアドレスを送信する', fn (User $user) => $this->patch('/profile', [
                'name' => 'Test User',
                'email' => $user->email,
            ]))
            ->then('セッションエラーがない', fn ($response) => $response->assertSessionHasNoErrors())
            ->and('プロフィール画面へリダイレクトされる', fn ($response) => $response->assertRedirect('/profile'))
            ->and('メール確認状態が維持される', function ($response, User $user): void {
                $this->assertNotNull($user->refresh()->email_verified_at);
            })
            ->run();
    }

    public function test_user_can_delete_their_account(): void
    {
        scenario('正しいパスワードでアカウントを削除する')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('正しいパスワードで削除を送信する', fn () => $this->delete('/profile', [
                'password' => 'password',
            ]))
            ->then('セッションエラーがない', fn ($response) => $response->assertSessionHasNoErrors())
            ->and('トップページへリダイレクトされる', fn ($response) => $response->assertRedirect('/'))
            ->and('ゲスト状態になる', function (): void {
                $this->assertGuest();
            })
            ->and('ユーザーが削除される', function ($response, User $user): void {
                $this->assertNotInstanceOf(User::class, $user->fresh());
            })
            ->run();
    }

    public function test_correct_password_must_be_provided_to_delete_account(): void
    {
        scenario('誤ったパスワードでアカウント削除を試みる')
            ->given('ログイン済みユーザー', function (): User {
                $user = User::factory()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('誤ったパスワードで削除を送信する', fn () => $this->from('/profile')->delete('/profile', [
                'password' => 'wrong-password',
            ]))
            ->then('パスワードにエラーがある', fn ($response) => $response->assertSessionHasErrors('password'))
            ->and('プロフィール画面へ戻る', fn ($response) => $response->assertRedirect('/profile'))
            ->and('ユーザーは削除されない', function ($response, User $user): void {
                $this->assertInstanceOf(User::class, $user->fresh());
            })
            ->run();
    }
}
