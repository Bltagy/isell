<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DriverSeeder extends Seeder
{
    public function run(): void
    {
        $drivers = [
            ['name' => 'Ahmed Sayed',    'email' => 'driver1@demo.com', 'phone' => '+201011111111'],
            ['name' => 'Mohamed Farouk', 'email' => 'driver2@demo.com', 'phone' => '+201022222222'],
            ['name' => 'Khaled Nasser',  'email' => 'driver3@demo.com', 'phone' => '+201033333333'],
            ['name' => 'Tarek Mostafa',  'email' => 'driver4@demo.com', 'phone' => '+201044444444'],
            ['name' => 'Hassan Adel',    'email' => 'driver5@demo.com', 'phone' => '+201055555555'],
        ];

        foreach ($drivers as $data) {
            $user = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'name'               => $data['name'],
                    'phone'              => $data['phone'],
                    'password'           => Hash::make('password'),
                    'role'               => 'driver',
                    'is_active'          => true,
                    'email_verified_at'  => now(),
                    'phone_verified_at'  => now(),
                    'preferred_language' => 'ar',
                ]
            );

            UserProfile::firstOrCreate(['user_id' => $user->id]);
            $user->assignRole('Driver');
        }
    }
}
