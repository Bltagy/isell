# Operations Guide

## Architecture Overview

```
foodapp_central (MySQL DB)   ← stores tenants, domains, subscription plans
tenant_demo     (MySQL DB)   ← per-tenant: users, products, orders, settings
tenant_xxx      (MySQL DB)   ← each new tenant gets its own isolated database
```

---

## Storage Layout (outside Docker)

| Path | Contents |
|------|----------|
| `storage/mysql/` | All MySQL data files (persisted on host) |
| `storage/app/` | Laravel file uploads (images, etc.) |
| `storage/minio/` | MinIO object storage data |
| `storage/mysql_backup.sql` | Latest full database backup |

**Backup all databases:**
```bash
docker exec foodapp-mysql bash -c "mysqldump -uroot -proot --all-databases 2>/dev/null" > storage/mysql_backup_$(date +%Y%m%d).sql
```

**Restore from backup:**
```bash
docker exec -i foodapp-mysql bash -c "mysql -uroot -proot 2>/dev/null" < storage/mysql_backup_YYYYMMDD.sql
```

---

## Tenant Management

### List all tenants
```bash
docker compose exec laravel-app php artisan tinker --execute="
\App\Models\Tenant::with('domains')->get()->each(function(\$t) {
    echo \$t->id.' | DB: tenant_'.\$t->id.' | Domains: '.\$t->domains->pluck('domain')->join(', ').PHP_EOL;
});
"
```

### Create a new tenant
```bash
docker compose exec laravel-app php artisan tinker --execute="
\$tenant = \App\Models\Tenant::create(['id' => 'mystore']);
\$tenant->domains()->create(['domain' => 'mystore.yourdomain.com']);
echo 'Created tenant: '.\$tenant->id.PHP_EOL;
echo 'Database: tenant_'.\$tenant->id.PHP_EOL;
"
```
This automatically:
- Creates the database `tenant_mystore`
- Runs all tenant migrations
- The tenant is immediately accessible via its domain

### Create tenant admin user
```bash
docker compose exec laravel-app php artisan tinker --execute="
tenancy()->initialize(\App\Models\Tenant::find('mystore'));

\$user = \App\Models\User::create([
    'name'     => 'Store Admin',
    'email'    => 'admin@mystore.com',
    'phone'    => '+201000000001',
    'password' => bcrypt('password123'),
    'role'     => 'admin',
    'is_active'=> true,
]);
\$user->assignRole('Tenant_Admin');
echo 'Admin created: '.\$user->email.PHP_EOL;

tenancy()->end();
"
```

### Delete a tenant (drops its database)
```bash
docker compose exec laravel-app php artisan tinker --execute="
\App\Models\Tenant::find('mystore')->delete();
echo 'Tenant deleted';
"
```

### Add a domain to existing tenant
```bash
docker compose exec laravel-app php artisan tinker --execute="
\$tenant = \App\Models\Tenant::find('demo');
\$tenant->domains()->create(['domain' => 'newdomain.com']);
echo 'Domain added';
"
```

### Run migrations on all tenant databases
```bash
docker compose exec laravel-app php artisan tenants:migrate
```

### Run migrations on a specific tenant
```bash
docker compose exec laravel-app php artisan tenants:migrate --tenants=demo
```

### Seed a specific tenant
```bash
docker compose exec laravel-app php artisan tenants:seed --tenants=demo
```

---

## Accessing the Central Database

The central database (`foodapp_central`) stores:
- `tenants` — tenant records
- `domains` — domain → tenant mapping
- `subscription_plans` — available plans
- `tenant_subscriptions` — which tenant is on which plan

**Connect via MySQL client:**
```
Host:     127.0.0.1
Port:     3306
User:     foodapp
Password: (from .env DB_PASSWORD)
Database: foodapp_central
```

**Via artisan tinker (central context):**
```bash
docker compose exec laravel-app php artisan tinker
# Inside tinker — you're in central context by default:
> App\Models\Tenant::all()
> App\Models\Domain::all()
```

**Switch to a tenant context in tinker:**
```bash
docker compose exec laravel-app php artisan tinker --execute="
tenancy()->initialize(App\Models\Tenant::find('demo'));
// Now all queries hit tenant_demo database
echo DB::connection()->getDatabaseName();
tenancy()->end();
"
```

---

## Admin Dashboard Access

URL: `http://localhost:3000` (or your server IP on port 3000)

Default admin credentials are set per-tenant. To reset an admin password:
```bash
docker compose exec laravel-app php artisan tinker --execute="
tenancy()->initialize(\App\Models\Tenant::find('demo'));
\App\Models\User::where('role','admin')->first()->update(['password' => bcrypt('newpassword')]);
echo 'Password updated';
tenancy()->end();
"
```

---

## Mobile App Configuration

The mobile app auto-detects the tenant from the domain/IP it connects to.
- **Local dev:** Use `--dart-define=BASE_URL=http://YOUR_LAN_IP` — it falls back to the first tenant automatically.
- **Production:** Point the app to `https://store.yourdomain.com` — tenant is identified by domain.

---

## Common Commands

```bash
# Start everything
docker compose up -d

# Stop everything
docker compose down

# View logs
docker compose logs laravel-app --tail=50 -f
docker compose logs nginx --tail=50

# Reload nginx (after config changes)
docker compose exec nginx nginx -s reload

# Clear Laravel cache
docker compose exec laravel-app php artisan cache:clear
docker compose exec laravel-app php artisan config:clear
docker compose exec laravel-app php artisan route:clear

# Run central migrations only
docker compose exec laravel-app php artisan migrate --force

# Run tenant migrations on all tenants
docker compose exec laravel-app php artisan tenants:migrate --force

# Check queue health
docker compose exec laravel-app php artisan horizon:status
```

---

## Environment Files

| File | Purpose |
|------|---------|
| `.env` | Root-level Docker env vars (DB passwords, ports) |
| `backend/.env` | Laravel application config |
| `dashboard/.env.example` | Next.js dashboard config template |

**Key variables in `backend/.env`:**
```
TENANCY_CENTRAL_DOMAINS=localhost,192.168.1.8   # IPs/domains that bypass tenant detection
APP_URL=http://localhost
DB_DATABASE=foodapp_central
```
