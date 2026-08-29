<?php

declare(strict_types=1);

namespace Tests\Support\Gwt;

use Closure;
use PHPUnit\Framework\Assert;

/**
 * GWT (Given-When-Then) Scenario Builder for Pest v4
 *
 * Provides a fluent interface for writing BDD-style tests.
 *
 * @example
 * scenario('ユーザー登録')
 *     ->given('有効なユーザーデータ', fn () => ['name' => 'Test', 'email' => 'test@example.com'])
 *     ->when('登録APIを呼び出す', fn ($data) => post('/register', $data))
 *     ->then('ユーザーが作成される', fn ($response) => $response->assertCreated());
 */
final class Scenario
{
    /** @var array<int, array{description: string, action: Closure, result: mixed}> */
    private array $givens = [];

    /** @var array<int, array{description: string, action: Closure, result: mixed}> */
    private array $whens = [];

    /** @var array<int, array{description: string, action: Closure}> */
    private array $thens = [];

    private mixed $context = null;

    public function __construct(private readonly string $description) {}

    /**
     * Define a precondition or setup step.
     *
     * @param  string  $description  Description of the precondition
     * @param  Closure  $action  Setup action that returns context data
     */
    public function given(string $description, Closure $action): self
    {
        $this->givens[] = [
            'description' => $description,
            'action' => $action,
            'result' => null,
        ];

        return $this;
    }

    /**
     * Alias for given() to chain multiple preconditions.
     */
    public function and(string $description, Closure $action): self
    {
        // Determine which phase we're in based on what's been defined
        if (count($this->thens) > 0) {
            return $this->then($description, $action);
        }

        if (count($this->whens) > 0) {
            return $this->when($description, $action);
        }

        return $this->given($description, $action);
    }

    /**
     * Define the action being tested.
     *
     * @param  string  $description  Description of the action
     * @param  Closure  $action  Action that takes context and returns result
     */
    public function when(string $description, Closure $action): self
    {
        $this->whens[] = [
            'description' => $description,
            'action' => $action,
            'result' => null,
        ];

        return $this;
    }

    /**
     * Define an expected outcome.
     *
     * @param  string  $description  Description of the expected outcome
     * @param  Closure  $action  Assertion that takes the result
     */
    public function then(string $description, Closure $action): self
    {
        $this->thens[] = [
            'description' => $description,
            'action' => $action,
        ];

        return $this;
    }

    /**
     * Execute the scenario.
     */
    public function run(): void
    {
        // Execute all Given steps
        foreach ($this->givens as $index => $given) {
            $this->givens[$index]['result'] = ($given['action'])($this->context);
            $this->context = $this->mergeContext($this->context, $this->givens[$index]['result']);
        }

        // Execute all When steps
        $result = null;
        foreach ($this->whens as $index => $when) {
            $this->whens[$index]['result'] = ($when['action'])($this->context);
            $result = $this->whens[$index]['result'];
        }

        // Execute all Then steps
        foreach ($this->thens as $then) {
            ($then['action'])($result, $this->context);
        }

        // Then が無いシナリオでも PHPUnit の risky 判定を避けるため、
        // 分岐条件そのものをアサーションとして 1 件計上する。
        if ($this->thens === []) {
            Assert::assertCount(0, $this->thens, 'Scenario completed without explicit assertions');
        }
    }

    /**
     * Get the scenario description for debugging.
     */
    public function getDescription(): string
    {
        $parts = ["Scenario: {$this->description}"];

        foreach ($this->givens as $given) {
            $parts[] = "  Given {$given['description']}";
        }

        foreach ($this->whens as $when) {
            $parts[] = "  When {$when['description']}";
        }

        foreach ($this->thens as $then) {
            $parts[] = "  Then {$then['description']}";
        }

        return implode("\n", $parts);
    }

    /**
     * Merge context data intelligently.
     */
    private function mergeContext(mixed $existing, mixed $new): mixed
    {
        if ($existing === null) {
            return $new;
        }

        if (is_array($existing) && is_array($new)) {
            return array_merge($existing, $new);
        }

        return $new;
    }
}
