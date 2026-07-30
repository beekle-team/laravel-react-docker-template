<?php

declare(strict_types=1);

namespace App\Models\Gateway;

use Illuminate\Http\Client\PendingRequest;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;
use LogicException;

abstract class Model
{
    protected const int TIMEOUT = 60;

    private const array HTTP_METHODS = [
        'GET',
        'POST',
        'PUT',
        'PATCH',
        'DELETE',
    ];

    /**
     * @param  array<string, mixed>  $options
     */
    public function __construct(
        protected readonly array $options = [],
    ) {}

    /**
     * @param  array<string, mixed>  $params
     * @param  array<string, string>  $headers
     * @return array<string, mixed>
     */
    protected function get(string $url, array $params = [], array $headers = []): array
    {
        return $this->request('GET', $url, $params, $headers);
    }

    /**
     * @param  array<string, mixed>  $params
     * @param  array<string, string>  $headers
     * @return array<string, mixed>
     */
    protected function post(string $url, array $params = [], array $headers = []): array
    {
        return $this->request('POST', $url, $params, $headers);
    }

    /**
     * @param  array<string, mixed>  $params
     * @param  array<string, string>  $headers
     * @return array<string, mixed>
     */
    protected function put(string $url, array $params = [], array $headers = []): array
    {
        return $this->request('PUT', $url, $params, $headers);
    }

    /**
     * @param  array<string, mixed>  $params
     * @param  array<string, string>  $headers
     * @return array<string, mixed>
     */
    protected function patch(string $url, array $params = [], array $headers = []): array
    {
        return $this->request('PATCH', $url, $params, $headers);
    }

    /**
     * @param  array<string, mixed>  $params
     * @param  array<string, string>  $headers
     * @return array<string, mixed>
     */
    protected function delete(string $url, array $params = [], array $headers = []): array
    {
        return $this->request('DELETE', $url, $params, $headers);
    }

    /**
     * @param  array<string, mixed>  $params
     * @param  array<string, string>  $headers
     * @return array<string, mixed>
     */
    protected function request(string $method, string $url, array $params = [], array $headers = []): array
    {
        $method = Str::upper($method);

        if (! in_array($method, self::HTTP_METHODS, true)) {
            throw new LogicException("Unsupported gateway HTTP method [{$method}].");
        }

        $pendingRequest = Http::timeout(static::TIMEOUT)->withHeaders($headers);
        $response = $this->customPendingRequest($pendingRequest)
            ->send($method, $url, ['json' => $params])
            ->throw();

        return $response->json() ?? [];
    }

    protected function customPendingRequest(PendingRequest $pendingRequest): PendingRequest
    {
        return $pendingRequest;
    }
}
