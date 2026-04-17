# SaaS Food Ordering System

A production-ready, multi-tenant SaaS food ordering platform consisting of:

- **Laravel 11 API** — multi-tenant backend with stancl/tenancy
- **Next.js 14 Dashboard** — bilingual (EN/AR) admin panel
- **Flutter 3.x Mobile App** — customer-facing iOS/Android app

---

## Prerequisites

- Docker Desktop 24+ and Docker Compose v2
- Make (pre-installed on macOS/Linux)
- Flutter 3.19+ (for mobile development only)
- Node.js 20+ (for dashboard development only)

---

## Quick Start

### 1. Clone and configure environment

```bash
cp .env.example .env
```

Edit `.env` and set at minimum:
- `APP_KEY` — generate with `make shell` then `php artisan key:generate`
- `DB_ROOT_PASSWORD`, `DB_PASSWORD`
- `MINIO_ROOT_USER`, `MINIO_ROOT_PASSWORD`

### 2. Start all services

```bash
make up
```

This builds and starts all 10 Docker services. First run takes ~3–5 minutes.

### 3. Run migrations and seed demo data

```bash
make migrate
make seed
```

The seeder creates:
- 3 subscription plans (Basic, Pro, Enterprise)
- 1 demo tenant at `demo.localhost`
- 15 products across 3 categories (Burgers, Pizza, Drinks)
- 5 demo customers, 3 drivers, 10 sample orders
- 3 active promo codes

---

## Accessing Services

| Service | URL | Credentials |
|---------|-----|-------------|
| Laravel API | http://demo.localhost/api/v1 | — |
| Next.js Dashboard | http://localhost:3000 | admin@demo.com / password |
| MinIO Console | http://localhost:9001 | minioadmin / minioadmin123 |
| Mailpit (dev mail) | http://localhost:8025 | — |
| Meilisearch | http://localhost:7700 | — |
| Laravel Horizon | http://demo.localhost/horizon | — |

---

## Makefile Targets

```bash
make up        # Start all containers (build if needed)
make down      # Stop all containers
make migrate   # Run Laravel migrations
make seed      # Run database seeders
make fresh     # Drop all tables, re-migrate, and re-seed
make test      # Run Laravel test suite
make shell     # Open bash shell in laravel-app container
make logs      # Tail logs from all services
make artisan cmd="route:list"  # Run any artisan command
```

---

## Project Structure

```
.
├── backend/          # Laravel 11 API
├── dashboard/        # Next.js 14 Admin Dashboard
├── mobile/           # Flutter 3.x Mobile App
├── docker/           # Docker configuration files
│   ├── nginx/        # Nginx config
│   ├── php/          # PHP Dockerfile and php.ini
│   └── mysql/        # MySQL init scripts
├── postman/          # Postman collection and environment
├── docker-compose.yml
├── docker-compose.prod.yml
├── .env.example
└── Makefile
```

---

## Multi-Tenancy

The system uses subdomain-based tenant routing via `stancl/tenancy`.

- Central DB: `foodapp_central` — stores tenants, plans, subscriptions
- Tenant DBs: `tenant_{id}` — isolated per tenant

To provision a new tenant via API:
```bash
POST http://localhost/central/api/tenants
{
  "name": "My Restaurant",
  "email": "owner@myrestaurant.com",
  "slug": "myrestaurant"
}
```

Access the tenant at: `http://myrestaurant.localhost`

---

## Production Deployment

```bash
# Use production compose override
docker compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

The production config:
- Removes all debug port bindings
- Adds resource limits to all services
- Configures SSL via Let's Encrypt (certbot volumes)
- Sets `APP_ENV=production`, `APP_DEBUG=false`

---

## Running Tests

**Laravel:**
```bash
make test
# or
make artisan cmd="test --filter=OrderCreationTest"
```

**Next.js:**
```bash
cd dashboard && npm test
```

**Flutter:**
```bash
cd mobile && flutter test
```

---

## Environment Variables

See `.env.example` for a fully documented list of all environment variables with inline descriptions.

Key variables to configure for production:
- `APP_KEY` — Laravel encryption key
- `KASHIER_MERCHANT_ID`, `KASHIER_API_KEY` — payment gateway credentials
- `FIREBASE_CREDENTIALS` — path to Firebase service account JSON
- `MEILISEARCH_KEY` — Meilisearch master key
- `AWS_*` — MinIO/S3 credentials for media storage
