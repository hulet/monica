# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Monica is a Personal Relationship Management (PRM) system — a self-hosted app for managing personal relationships (contacts, activities, reminders, gifts, notes). This is a personal fork of Monica v4 (Laravel/PHP backend + Vue.js frontend). Upstream development stalled; this fork is maintained for personal self-hosting.

## Development Commands

### Initial Setup
```bash
composer install --no-interaction
cp .env.example .env
php artisan key:generate
yarn install
yarn run dev
php artisan setup:test --skipSeed   # initialize DB without fake data
php artisan passport:install         # set up OAuth tokens
```

### Asset Compilation
```bash
yarn run dev        # compile assets (also runs php artisan lang:generate)
yarn run prod       # production build
yarn run watch      # watch mode
```

### Running Tests
```bash
vendor/bin/phpunit                           # all PHP tests
vendor/bin/phpunit --filter=TestClassName    # single test class
vendor/bin/phpunit --testsuite Unit-Models   # specific suite
vendor/bin/phpunit --testsuite Unit-Services
vendor/bin/phpunit --testsuite Feature
vendor/bin/phpunit --testsuite Api
vendor/bin/phpunit --testsuite Commands-Other
vendor/bin/phpunit --testsuite Commands-Scheduling
```

Tests use the `testing` DB connection (configured in `phpunit.xml`). Reset the test DB with:
```bash
DB_CONNECTION=testing php artisan migrate:fresh && DB_CONNECTION=testing php artisan db:seed
```

### Linting
```bash
yarn run lint          # lint JS/Vue in resources/js/
yarn run lint:fix      # auto-fix
vendor/bin/phpstan analyse
vendor/bin/psalm
```

### Docker (development)
```bash
docker compose -f docker-compose.dev.yml up
# App: localhost:8080, phpMyAdmin: localhost:3000, MailHog: localhost:8025
```

## Architecture

### Stack
- **Backend:** Laravel 9, PHP 8.1+, MySQL 8
- **Frontend:** Vue.js 2.x, Bootstrap 4, Tachyons (atomic CSS), Laravel Mix 6
- **API:** RESTful + Passport OAuth 2.0
- **Protocols:** CardDAV/CalDAV via Sabre DAV

### Key Conventions
- **Multi-tenancy:** Every model has `account_id` — all queries must be scoped to the current account
- **Service layer:** Business logic lives in `app/Services/`, not controllers
- **UUIDs:** Models use the `HasUuid` trait for public IDs
- **Soft deletes:** Most models use soft deletes for data preservation
- **Object calisthenics:** Classes stay focused and small (max ~100 lines)

### Request Flow
1. Routes (`routes/web.php`, `routes/api.php`) → Controllers
2. Controllers call Services for business logic
3. Services operate on Eloquent models, fire Events
4. Jobs handle async work (email, reminders)

### Frontend Pattern
- Blade templates for page structure (in `resources/views/`)
- Vue.js components for interactive UI (in `resources/js/`)
- i18n via `vue-i18n`; PHP lang files generated into JS via `php artisan lang:generate` (runs automatically before asset compilation)
- API calls from Vue use Axios

### Key Directories
| Path | Purpose |
|------|---------|
| `app/Models/` | Eloquent models — Contact, Account, User, Relationship, Activity, Reminder, etc. |
| `app/Http/Controllers/` | Web controllers |
| `app/Http/Controllers/Api/` | API controllers |
| `app/Services/` | Business logic |
| `app/Console/Commands/` | Artisan commands (scheduled reminders, stats, sync) |
| `resources/js/` | Vue components |
| `resources/views/` | Blade templates |
| `tests/` | PHPUnit tests (Api, Feature, Unit, Commands) |
| `tests/cypress/` | Cypress E2E tests |

### Scheduled Commands
`app/Console/Kernel.php` defines the schedule: hourly reminders, daily statistics, weekly Gravatar updates, etc.

### DAV Support
CardDAV and CalDAV are handled via Sabre DAV. Routes are in `routes/dav.php`; controllers in `app/Http/Controllers/DAV/`.
