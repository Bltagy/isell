<?php

namespace Database\Seeders;

use App\Models\CentralUser;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

/**
 * Seeds the central (non-tenant) super admin user.
 * Run with: php artisan db:seed --class=SuperAdminSeeder
 */
class SuperAdminSeeder extends Seeder
{
    public function run(): void
    {
        $email    = env('SUPER_ADMIN_EMAILS', 'superadmin@example.com');
        $email    = trim(explode(',', $email)[0]); // use first email if multiple

        CentralUser::updateOrCreate(
            ['email' => $email],
            [
                'name'               => 'Super Admin',
                'password'           => Hash::make(env('SUPER_ADMIN_PASSWORD', 'SuperAdmin@123')),
                'email_verified_at'  => now(),
            ]
        );

        $this->command->info("Super admin created: {$email}");
    }
}
