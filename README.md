# Laravel + React + Inertia Docker Template

A production-ready Docker template for Laravel 12 with React, Inertia.js, and TypeScript.

## Features

- **Laravel 12** with PHP 8.3+
- **React 18** with TypeScript
- **Inertia.js** for seamless SPA experience
- **PostgreSQL** database
- **Redis** for caching/sessions
- **Pest v4** + **Playwright** for fast E2E testing
- **Larastan** (PHPStan) for static analysis
- **Biome** for JS/TS linting and formatting
- **Laravel Pint** for PHP code style
- **Laravel Data** + **TypeScript Transformer** for type-safe DTOs

## Tech Stack & Key Libraries

This template is curated to provide a modern, type-safe, and developer-friendly experience.

### Backend (PHP)
- **[Spatie Laravel Data](https://spatie.be/docs/laravel-data)**: Used for Data Transfer Objects (DTOs). It handles validation and transformation, serving as the source of truth for data structures.
- **[Larastan](https://github.com/larastan/larastan)**: Runs PHPStan on your Laravel code to find errors without running the code. Configured in `phpstan.neon` (default level: 5).
- **[Laravel Pint](https://laravel.com/docs/pint)**: An opinionated PHP code style fixer. Configured in `pint.json` (preset: laravel, strict types enabled).

### Frontend (React)
- **[Inertia.js](https://inertiajs.com/)**: Allows building single-page apps using classic server-side routing and controllers. No separate API required.
- **[Biome](https://biomejs.dev/)**: A fast all-in-one toolchain for web projects. It replaces Prettier and ESLint for formatting and linting TypeScript/React code.
- **[Tailwind CSS](https://tailwindcss.com/)**: A utility-first CSS framework for rapid UI development.

### Type Safety Bridge
- **[Laravel Data + TypeScript Transformer](https://spatie.be/docs/typescript-transformer)**: Automatically generates TypeScript interfaces from your PHP Data classes. This ensures your frontend types are always in sync with your backend data structures.

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

# Run E2E tests (Playwright)
docker compose exec app npm run test:e2e

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

### Playwright (E2E Tests)

Browser tests powered by Playwright.

```bash
docker compose exec app npm run test:e2e
```

By default the tests hit `http://localhost:8080`. Override with `PLAYWRIGHT_BASE_URL` if needed.
Run `docker compose exec app npm run test:e2e:install` once to download browser binaries for the container.

## Docker Services

| Service | Port | Description |
|---------|------|-------------|
| app | - | PHP-FPM application |
| nginx | 8080 | Web server |
| postgres | 5432 | Main database |
| postgres-test | 5433 | Test database |
| redis | 6379 | Cache/Queue |

## IDE Support

To ensure the best development experience with autocompletion and type checking, this project uses [Laravel IDE Helper](https://github.com/barryvdh/laravel-ide-helper).

Helper files are generated automatically using the following commands:

```bash
# Generate helper file for Facades
docker compose exec app php artisan ide-helper:generate

# Generate PHPDocs for Models
docker compose exec app php artisan ide-helper:models -N

# Generate PhpStorm/VSCode meta file
docker compose exec app php artisan ide-helper:meta
```

**Note:** These files (`_ide_helper.php`, `_ide_helper_models.php`, `.phpstorm.meta.php`) are already included and ignored in git to prevent conflicts, but you should regenerate them when:
1. You add new packages/Facades.
2. You modify database migrations/schema.

## License

MIT
