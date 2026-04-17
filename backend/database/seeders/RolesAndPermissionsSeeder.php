<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;
use Spatie\Permission\Models\Role;
use Spatie\Permission\Models\Permission;

class RolesAndPermissionsSeeder extends Seeder
{
    public function run(): void
    {
        app()[\Spatie\Permission\PermissionRegistrar::class]->forgetCachedPermissions();

        $permissions = [
            // Orders
            'orders.view', 'orders.update', 'orders.delete',
            // Products
            'products.view', 'products.create', 'products.update', 'products.delete',
            // Categories
            'categories.view', 'categories.create', 'categories.update', 'categories.delete',
            // Customers
            'customers.view', 'customers.update',
            // Drivers
            'drivers.view', 'drivers.create', 'drivers.update', 'drivers.delete',
            // Offers
            'offers.view', 'offers.create', 'offers.update', 'offers.delete',
            // Banners
            'banners.view', 'banners.create', 'banners.update', 'banners.delete',
            // Settings
            'settings.view', 'settings.update',
            // Notifications
            'notifications.broadcast',
            // Dashboard
            'dashboard.view',
        ];

        foreach ($permissions as $permission) {
            Permission::firstOrCreate(['name' => $permission, 'guard_name' => 'web']);
        }

        // Admin — all permissions
        $admin = Role::firstOrCreate(['name' => 'Tenant_Admin', 'guard_name' => 'web']);
        $admin->syncPermissions($permissions);

        // Branch Manager
        $manager = Role::firstOrCreate(['name' => 'Branch_Manager', 'guard_name' => 'web']);
        $manager->syncPermissions([
            'orders.view', 'orders.update',
            'products.view', 'products.create', 'products.update',
            'categories.view',
            'customers.view',
            'drivers.view',
            'dashboard.view',
        ]);

        // Driver
        $driver = Role::firstOrCreate(['name' => 'Driver', 'guard_name' => 'web']);
        $driver->syncPermissions(['orders.view', 'orders.update']);

        // Customer
        Role::firstOrCreate(['name' => 'Customer', 'guard_name' => 'web']);
    }
}
