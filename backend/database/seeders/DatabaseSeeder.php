<?php

namespace Database\Seeders;

use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use Illuminate\Database\Seeder;
use Stancl\Tenancy\Database\DatabaseManager;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        // ── Subscription Plans ────────────────────────────────
        $plans = [
            ['name' => 'Basic',      'max_products' => 50,   'max_orders_per_month' => 500,   'max_branches' => 1,  'price_monthly' => 29900,  'price_yearly' => 299000,  'features_json' => ['basic_analytics', 'email_support'],                                   'is_active' => true],
            ['name' => 'Pro',        'max_products' => 200,  'max_orders_per_month' => 2000,  'max_branches' => 3,  'price_monthly' => 79900,  'price_yearly' => 799000,  'features_json' => ['advanced_analytics', 'priority_support', 'custom_domain'],            'is_active' => true],
            ['name' => 'Enterprise', 'max_products' => 9999, 'max_orders_per_month' => 99999, 'max_branches' => 99, 'price_monthly' => 199900, 'price_yearly' => 1999000, 'features_json' => ['full_analytics', 'dedicated_support', 'custom_domain', 'api_access'], 'is_active' => true],
        ];

        foreach ($plans as $plan) {
            SubscriptionPlan::updateOrCreate(['name' => $plan['name']], $plan);
        }

        $starterPlan = SubscriptionPlan::where('name', 'Basic')->first();

        // ── Demo Tenant ───────────────────────────────────────
        // Use updateOrCreate without firing tenancy events
        $tenant = Tenant::withoutEvents(function () {
            return Tenant::updateOrCreate(
                ['id' => 'demo'],
                [
                    'name'   => 'Demo Restaurant',
                    'email'  => 'demo@foodapp.com',
                    'status' => 'active',
                ]
            );
        });

        $tenant->domains()->firstOrCreate(['domain' => 'demo.localhost']);
        $tenant->domains()->firstOrCreate(['domain' => 'localhost']);

        // Create active subscription for demo tenant
        $tenant->subscriptions()->firstOrCreate(
            ['tenant_id' => $tenant->id],
            [
                'plan_id'   => $starterPlan->id,
                'start_date' => now()->toDateString(),
                'end_date'   => now()->addYear()->toDateString(),
                'status'     => 'active',
            ]
        );

        // ── Create & Migrate Tenant DB manually ───────────────
        tenancy()->initialize($tenant);

        // Create the database if it doesn't exist
        $dbManager = app(DatabaseManager::class);
        try {
            $dbManager->createTenantConnection($tenant);
            $dbManager->createDatabase($tenant);
        } catch (\Throwable $e) {
            // DB may already exist — continue
        }

        // Run tenant migrations
        \Artisan::call('tenants:migrate', [
            '--tenants' => [$tenant->id],
            '--force'   => true,
        ]);

        // ── Seed Tenant Data ──────────────────────────────────
        $this->call(TenantDatabaseSeeder::class);

        tenancy()->end();
    }
}
