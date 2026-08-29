<?php

declare(strict_types=1);

namespace Tests\Feature;

// use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

final class ExampleTest extends TestCase
{
    /**
     * A basic test example.
     */
    public function test_the_application_returns_a_successful_response(): void
    {
        scenario('トップページを表示する')
            ->given('未認証のユーザー', fn () => null)
            ->when('トップページへアクセスする', fn () => $this->get('/'))
            ->then('正常なレスポンスが返る', fn ($response) => $response->assertStatus(200))
            ->run();
    }
}
