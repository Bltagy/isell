# Food App — Laravel 11 Backend API

Multi-tenant SaaS food ordering system built with Laravel 11, MySQL 8, Redis, Meilisearch, MinIO, Laravel Reverb, and Laravel Horizon.

---

## Prerequisites

- Docker Desktop 4.x+
- Docker Compose v2+
- Make (optional but recommended)

---

## Installation

### 1. Clone and configure environment

```bash
cp .env.example .env
# Edit .env with your values (APP_KEY will be generated in step 3)
```

### 2. Start Docker services

```bash
make up
# or: docker compose up -d --build
```

### 3. Generate app key and run migrations

```bash
make key        # php artisan key:generate
make migrate    # php artisan migrate
make seed       # php artisan db:seed
```

### 4. (Optional) Fresh install with seed data

```bash
make fresh      # migrate:fresh --seed
```

---

## Environment Variables

| Variable | Description |
|---|---|
| `APP_KEY` | Laravel encryption key — generate with `php artisan key:generate` |
| `DB_DATABASE` | Central database name (default: `foodapp_central`) |
| `DB_USERNAME` / `DB_PASSWORD` | MySQL credentials |
| `REDIS_PASSWORD` | Redis auth password |
| `MEILISEARCH_KEY` | Meilisearch master key |
| `AWS_*` / `MINIO_*` | MinIO S3-compatible storage credentials |
| `REVERB_APP_KEY` / `REVERB_APP_SECRET` | Laravel Reverb WebSocket credentials |
| `KASHIER_MERCHANT_ID` / `KASHIER_API_KEY` | Kashier payment gateway |
| `FIREBASE_CREDENTIALS` | Path to Firebase service account JSON |

---

## API Base URL Structure

Each tenant is identified by subdomain:

```
http://{subdomain}.localhost/api/v1/...
```

Example:
```
http://demo.localhost/api/v1/home
http://demo.localhost/api/v1/auth/login
```

---

## Services & Ports

| Service | Port | URL |
|---|---|---|
| Nginx (API) | 80 | http://localhost |
| Laravel Reverb (WS) | 8060 | ws://localhost:8060 |
| MySQL | 3306 | localhost:3306 |
| Redis | 6379 | localhost:6379 |
| Meilisearch | 7700 | http://localhost:7700 |
| MinIO Console | 9001 | http://localhost:9001 |
| Mailpit | 8025 | http://localhost:8025 |
| Laravel Horizon | — | http://localhost/horizon |

---

## Demo Credentials

After seeding:

| Role | Email | Password |
|---|---|---|
| Admin | admin@foodapp.com | password |
| Customer | ahmed@example.com | password |

---

## Postman Collection

Import `postman_collection.json` from the project root.

Base URL variable: `{{base_url}}` = `http://demo.localhost/api/v1`

Auth: Bearer token from `/auth/login` response → set as `{{token}}` variable.

---

## Make Commands

```bash
make up       # Start all containers
make down     # Stop all containers
make bash     # Shell into app container
make migrate  # Run migrations
make seed     # Run seeders
make fresh    # Fresh migrate + seed
make logs     # Follow container logs
make horizon  # Restart Horizon worker
make reverb   # Restart Reverb WebSocket server
make tinker   # Laravel Tinker REPL
make test     # Run PHPUnit tests
make clear    # Clear all caches
```

---

## Architecture

- Repository pattern for all data access
- Service classes for all business logic
- API Resources for all responses
- Form Requests for all validation
- PSR-12 code style
- All money values stored as integers (piastres) — 100 piastres = 1 EGP
