# Laravel + React + Inertia Docker Template

A production-ready Docker template for Laravel 12 with React, Inertia.js, and TypeScript.

## Features

- **Laravel 12** with PHP 8.3+
- **React 18** with TypeScript
- **Inertia.js** for seamless SPA experience
- **PostgreSQL** database
- **Redis** for caching/sessions
- **Laravel Dusk** for E2E testing with Selenium
- **Larastan** (PHPStan) for static analysis
- **Biome** for JS/TS linting and formatting
- **Laravel Pint** for PHP code style
- **Laravel Data** + **TypeScript Transformer** for type-safe DTOs

## Requirements

- Docker & Docker Compose
- Node.js 20+ (for local development)

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd laravel-react-docker-template

# Copy environment file
cp .env.example .env

# Start containers
docker compose up -d

# Install dependencies & setup
docker compose exec app composer install
docker compose exec app npm install
docker compose exec app php artisan key:generate
docker compose exec app php artisan migrate

# Build assets
docker compose exec app npm run build

# Access the application
open http://localhost:8080
```

## Development

```bash
# Start Vite dev server (with HMR)
docker compose exec app npm run dev

# Run PHP tests
docker compose exec app php artisan test

# Run E2E tests (Dusk)
docker compose exec app php artisan dusk

# Static analysis
docker compose exec app ./vendor/bin/phpstan analyse

# Code formatting
docker compose exec app ./vendor/bin/pint
docker compose exec app npm run lint
```

## Laravel Data + TypeScript Generation

This template includes [spatie/laravel-data](https://spatie.be/docs/laravel-data) and [spatie/laravel-typescript-transformer](https://spatie.be/docs/typescript-transformer) for type-safe data transfer between PHP and TypeScript.

### Creating a Data Object

```php
<?php

declare(strict_types=1);

namespace App\Data;

use Spatie\LaravelData\Data;

class UserData extends Data
{
    public function __construct(
        public int $id,
        public string $name,
        public string $email,
        public ?string $avatar = null,
    ) {}
}
```

### Generate TypeScript Types

```bash
docker compose exec app php artisan typescript:transform
```

This generates types in `resources/js/types/generated.d.ts`:

```typescript
declare namespace App.Data {
    export type UserData = {
        id: number;
        name: string;
        email: string;
        avatar: string | null;
    };
}
```

### Using in React Components

```tsx
import { PageProps } from '@/types';

interface Props extends PageProps {
    user: App.Data.UserData;
}

export default function Profile({ user }: Props) {
    return <div>{user.name}</div>;
}
```

### Workflow

1. Create/modify Data classes in `app/Data/`
2. Run `php artisan typescript:transform`
3. Import generated types in your React components
4. Enjoy full type safety between backend and frontend

### Configuration

- PHP config: `config/typescript-transformer.php`
- Generated types: `resources/js/types/generated.d.ts`

## Testing

### PHPUnit (Unit & Feature Tests)

Tests run against a dedicated PostgreSQL test database.

```bash
docker compose exec app php artisan test
```

### Laravel Dusk (E2E Tests)

Browser tests using Selenium Chrome.

```bash
docker compose exec app php artisan dusk
```

View test screenshots in `tests/Browser/screenshots/`.

## Docker Services

| Service | Port | Description |
|---------|------|-------------|
| app | - | PHP-FPM application |
| nginx | 8080 | Web server |
| postgres | 5432 | Main database |
| postgres-test | 5433 | Test database |
| redis | 6379 | Cache/Queue |
| selenium | 4444, 7900 | Browser testing |

## IDE Support

IDE helper files are generated automatically:

```bash
docker compose exec app php artisan ide-helper:generate
docker compose exec app php artisan ide-helper:models -N
docker compose exec app php artisan ide-helper:meta
```

## License

MIT
