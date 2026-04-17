<?php

namespace App\Services;

use App\Mail\WelcomeTenantMail;
use App\Models\Tenant;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Support\Str;
use Stancl\Tenancy\Jobs\SeedDatabase;

class TenantService
{
    /**
     * Provision a new tenant:
     *  1. Create Tenant record in Central_DB
     *  2. Create primary Domain record
     *  3. TenantCreated event fires CreateDatabase + MigrateDatabase via TenancyServiceProvider
     *  4. Manually dispatch SeedDatabase job
     *  5. Create Tenant_Admin user inside tenant DB
     *  6. Dispatch WelcomeTenantMail
     */
    public function provision(array $data): Tenant
    {
        $slug   = $data['slug'] ?? Str::slug($data['name']);
        $domain = $slug.'.'.ltrim(config('app.domain', env('TENANCY_CENTRAL_DOMAINS', 'localhost')), '.');

        // 1. Create Tenant (fires TenantCreated → CreateDatabase + MigrateDatabase)
        $tenant = Tenant::create([
            'id'     => $slug,
            'name'   => $data['name'],
            'email'  => $data['email'],
            'status' => 'active',
        ]);

        // 2. Create primary Domain
        $tenant->domains()->create([
            'domain'     => $domain,
            'is_primary' => true,
        ]);

        // 3. Seed the tenant database
        SeedDatabase::dispatchSync($tenant);

        // 4. Create Tenant_Admin user inside tenant DB
        $password = Str::random(12);

        tenancy()->initialize($tenant);

        $adminUser = \App\Models\User::create([
            'name'               => $data['name'].' Admin',
            'email'              => $data['email'],
            'password'           => Hash::make($password),
            'role'               => 'Tenant_Admin',
            'is_active'          => true,
            'preferred_language' => 'en',
        ]);

        if (class_exists(\Spatie\Permission\Models\Role::class)) {
            $adminUser->assignRole('Tenant_Admin');
        }

        tenancy()->end();

        // 5. Dispatch welcome email
        Mail::to($data['email'])->queue(new WelcomeTenantMail(
            tenant: $tenant,
            adminEmail: $data['email'],
            adminPassword: $password,
            domain: $domain,
        ));

        return $tenant->load('domains');
    }
}
