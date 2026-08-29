<?php

declare(strict_types=1);

namespace Tests\Support\Gwt;

use Closure;
use LogicException;
use PHPUnit\Framework\Assert;

/**
 * GWT (Given-When-Then) Scenario Builder for Pest v4.
 *
 * A Scenario has one business action and at least one precondition and
 * expectation. Invalid order is rejected while the scenario is being built,
 * so an incomplete acceptance test cannot be reported as passing evidence.
 *
 * @example
 * scenario('ユーザー登録')
 *     ->given('有効なユーザーデータ', fn () => ['name' => 'Test', 'email' => 'test@example.com'])
 *     ->when('登録APIを呼び出す', fn ($data) => post('/register', $data))
 *     ->then('ユーザーが作成される', fn ($response) => $response->assertCreated())
 *     ->run();
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

    private bool $hasRun = false;

    public function __construct(private readonly string $description) {}

    /**
     * Define a precondition or setup step.
     */
    public function given(string $description, Closure $action): self
    {
        if ($this->whens !== [] || $this->thens !== []) {
            throw new LogicException('When の後に Given は追加できません。');
        }

        $this->givens[] = [
            'description' => $description,
            'action' => $action,
            'result' => null,
        ];

        return $this;
    }

    /**
     * Continue the current Given or Then phase.
     */
    public function and(string $description, Closure $action): self
    {
        if ($this->thens !== []) {
            return $this->then($description, $action);
        }

        if ($this->whens !== []) {
            throw new LogicException('When の後の And は追加の操作ではなく Then として記述してください。');
        }

        if ($this->givens === []) {
            throw new LogicException('And を定義する前に Given が必要です。');
        }

        return $this->given($description, $action);
    }

    /**
     * Define the single business action being tested.
     */
    public function when(string $description, Closure $action): self
    {
        if ($this->givens === []) {
            throw new LogicException('When を定義する前に Given が必要です。');
        }

        if ($this->whens !== []) {
            throw new LogicException('When は1つの Scenario につき一度だけ定義できます。');
        }

        if ($this->thens !== []) {
            throw new LogicException('Then の後に When は追加できません。');
        }

        $this->whens[] = [
            'description' => $description,
            'action' => $action,
            'result' => null,
        ];

        return $this;
    }

    /**
     * Define an expected outcome.
     */
    public function then(string $description, Closure $action): self
    {
        if ($this->whens === []) {
            throw new LogicException('Then を定義する前に When が必要です。');
        }

        $this->thens[] = [
            'description' => $description,
            'action' => $action,
        ];

        return $this;
    }

    /**
     * Execute the scenario once.
     */
    public function run(): void
    {
        if ($this->hasRun) {
            throw new LogicException('Scenario は一度だけ実行できます。');
        }

        if ($this->givens === []) {
            Assert::fail('Scenario には最低1つの Given が必要です。');
        }

        if ($this->whens === []) {
            Assert::fail('Scenario には1つの When が必要です。');
        }

        if ($this->thens === []) {
            Assert::fail('Scenario には最低1つの Then が必要です。');
        }

        $this->hasRun = true;

        foreach ($this->givens as $index => $given) {
            $this->givens[$index]['result'] = ($given['action'])($this->context);
            $this->context = $this->mergeContext($this->context, $this->givens[$index]['result']);
        }

        $when = $this->whens[0];
        $this->whens[0]['result'] = ($when['action'])($this->context);
        $result = $this->whens[0]['result'];

        foreach ($this->thens as $then) {
            ($then['action'])($result, $this->context);
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
