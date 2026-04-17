<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

/**
 * Seeder that runs inside each tenant database.
 */
class TenantDatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $this->call([
            TenantSettingsSeeder::class,
            RolesAndPermissionsSeeder::class,
            AdminUserSeeder::class,
            CategorySeeder::class,
            ProductSeeder::class,
            BannerSeeder::class,
            OfferSeeder::class,
            CustomerSeeder::class,
            DriverSeeder::class,
            OrderSeeder::class,
        ]);
    }
}
