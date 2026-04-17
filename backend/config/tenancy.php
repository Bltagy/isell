<?php

declare(strict_types=1);

use App\Models\Domain;
use App\Models\Tenant;

return [
    'tenant_model' => Tenant::class,
    'id_generator' => Stancl\Tenancy\Database\Concerns\GeneratesIds::class,

    'domain_model' => Domain::class,

    'central_domains' => explode(',', env('TENANCY_CENTRAL_DOMAINS', 'localhost')),

    'bootstrappers' => [
        Stancl\Tenancy\Bootstrappers\DatabaseTenancyBootstrapper::class,
        Stancl\Tenancy\Bootstrappers\CacheTenancyBootstrapper::class,
        Stancl\Tenancy\Bootstrappers\FilesystemTenancyBootstrapper::class,
        Stancl\Tenancy\Bootstrappers\QueueTenancyBootstrapper::class,
    ],

    'database' => [
        'central_connection' => env('DB_CONNECTION', 'mysql'),
        'template_tenant_connection' => null,
        'prefix' => 'tenant_',
        'suffix' => '',
        'managers' => [
            'mysql'  => Stancl\Tenancy\TenantDatabaseManagers\MySQLDatabaseManager::class,
            'sqlite' => Stancl\Tenancy\TenantDatabaseManagers\SQLiteDatabaseManager::class,
        ],
    ],

    'cache' => [
        'tag' => 'tenancy',
    ],

    'filesystem' => [
        'suffix_base' => 'tenant',
        'disks' => ['local', 'public', 's3'],
        'root_override' => [
            'local' => '%storage_path%/app/',
            'public' => '%storage_path%/app/public/',
        ],
        'override_s3_bucket' => false,
    ],

    'redis' => [
        'prefix_base' => 'tenant',
        'prefixed_connections' => ['default', 'cache'],
    ],

    'features' => [
        Stancl\Tenancy\Features\UserImpersonation::class,
        Stancl\Tenancy\Features\TelescopeTags::class,
        Stancl\Tenancy\Features\UniversalRoutes::class,
    ],

    'migration_parameters' => [
        '--force' => true,
        '--path' => [database_path('migrations/tenant')],
        '--realpath' => true,
    ],

    'seeder_parameters' => [
        '--class' => 'TenantDatabaseSeeder',
        '--force' => true,
    ],
];
