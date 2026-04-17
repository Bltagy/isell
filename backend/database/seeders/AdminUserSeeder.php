<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::updateOrCreate(
            ['email' => 'admin@foodapp.com'],
            [
                'name'               => 'Admin User',
                'email'              => 'admin@foodapp.com',
                'phone'              => '+201000000001',
                'password'           => Hash::make('password'),
                'role'               => 'admin',
                'is_active'          => true,
                'email_verified_at'  => now(),
                'phone_verified_at'  => now(),
                'preferred_language' => 'ar',
            ]
        );

        UserProfile::firstOrCreate(['user_id' => $admin->id], [
            'loyalty_points' => 0,
        ]);

        $admin->assignRole('Tenant_Admin');
    }
}
