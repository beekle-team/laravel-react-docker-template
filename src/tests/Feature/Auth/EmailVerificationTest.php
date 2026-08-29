<?php

declare(strict_types=1);

namespace Tests\Feature\Auth;

use App\Models\Eloquent\User;
use Illuminate\Auth\Events\Verified;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Event;
use Illuminate\Support\Facades\URL;
use Tests\TestCase;

final class EmailVerificationTest extends TestCase
{
    use RefreshDatabase;

    public function test_email_verification_screen_can_be_rendered(): void
    {
        scenario('メール確認画面を表示する')
            ->given('未確認メールのログイン済みユーザー', function (): User {
                $user = User::factory()->unverified()->create();
                $this->actingAs($user);

                return $user;
            })
            ->when('メール確認画面へアクセスする', fn () => $this->get('/verify-email'))
            ->then('画面が正常に表示される', fn ($response) => $response->assertStatus(200))
            ->run();
    }

    public function test_email_can_be_verified(): void
    {
        scenario('有効な署名URLでメールを確認する')
            ->given('未確認メールのユーザーと有効な署名URL', function (): array {
                $user = User::factory()->unverified()->create();
                $this->actingAs($user);
                Event::fake();

                return [
                    'user' => $user,
                    'url' => URL::temporarySignedRoute(
                        'verification.verify',
                        now()->addMinutes(60),
                        ['id' => $user->id, 'hash' => sha1($user->email)]
                    ),
                ];
            })
            ->when('署名URLへアクセスする', fn (array $context) => $this->get($context['url']))
            ->then('確認イベントが発行される', fn () => Event::assertDispatched(Verified::class))
            ->and('メールが確認済みになる', function ($response, array $context): void {
                $this->assertTrue($context['user']->refresh()->hasVerifiedEmail());
            })
            ->and('確認完了付きダッシュボードへリダイレクトされる', fn ($response) => $response->assertRedirect(route('dashboard', absolute: false).'?verified=1'))
            ->run();
    }

    public function test_email_is_not_verified_with_invalid_hash(): void
    {
        scenario('無効なハッシュでメール確認を試みる')
            ->given('未確認メールのユーザーと無効な署名URL', function (): array {
                $user = User::factory()->unverified()->create();
                $this->actingAs($user);

                return [
                    'user' => $user,
                    'url' => URL::temporarySignedRoute(
                        'verification.verify',
                        now()->addMinutes(60),
                        ['id' => $user->id, 'hash' => sha1('wrong-email')]
                    ),
                ];
            })
            ->when('無効な署名URLへアクセスする', fn (array $context) => $this->get($context['url']))
            ->then('メールは未確認のままになる', function ($response, array $context): void {
                $this->assertFalse($context['user']->refresh()->hasVerifiedEmail());
            })
            ->run();
    }
}
