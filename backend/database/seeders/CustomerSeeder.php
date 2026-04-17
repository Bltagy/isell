<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\UserAddress;
use App\Models\UserProfile;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class CustomerSeeder extends Seeder
{
    public function run(): void
    {
        $customers = [
            ['name' => 'Ahmed Mohamed',    'email' => 'ahmed@example.com',    'phone' => '+201111111111'],
            ['name' => 'Sara Ali',         'email' => 'sara@example.com',     'phone' => '+201222222222'],
            ['name' => 'Mohamed Hassan',   'email' => 'mhassan@example.com',  'phone' => '+201333333333'],
            ['name' => 'Nour Ibrahim',     'email' => 'nour@example.com',     'phone' => '+201444444444'],
            ['name' => 'Khaled Samir',     'email' => 'khaled@example.com',   'phone' => '+201555555555'],
            ['name' => 'Dina Mahmoud',     'email' => 'dina@example.com',     'phone' => '+201666666666'],
            ['name' => 'Omar Farouk',      'email' => 'omar@example.com',     'phone' => '+201777777777'],
            ['name' => 'Rania Tarek',      'email' => 'rania@example.com',    'phone' => '+201888888888'],
            ['name' => 'Youssef Adel',     'email' => 'youssef@example.com',  'phone' => '+201999999999'],
            ['name' => 'Mona Sherif',      'email' => 'mona@example.com',     'phone' => '+201010101010'],
        ];

        $districts = ['Nasr City', 'Maadi', 'Heliopolis', 'Zamalek', 'Dokki', 'Mohandessin', 'New Cairo', '6th of October'];

        foreach ($customers as $data) {
            $user = User::updateOrCreate(
                ['email' => $data['email']],
                [
                    'name'               => $data['name'],
                    'phone'              => $data['phone'],
                    'password'           => Hash::make('password'),
                    'role'               => 'customer',
                    'is_active'          => true,
                    'email_verified_at'  => now(),
                    'phone_verified_at'  => now(),
                    'preferred_language' => 'ar',
                ]
            );

            UserProfile::firstOrCreate(['user_id' => $user->id], [
                'loyalty_points' => rand(0, 1000),
            ]);

            $user->assignRole('Customer');

            if ($user->addresses()->count() === 0) {
                UserAddress::create([
                    'user_id'       => $user->id,
                    'label'         => 'home',
                    'address_line1' => rand(1, 99).' '.['Tahrir St', 'Nile Corniche', 'Salah Salem', 'Ring Road', 'Abbas El Akkad'][rand(0, 4)],
                    'city'          => 'Cairo',
                    'district'      => $districts[array_rand($districts)],
                    'latitude'      => 30.0444 + (rand(-500, 500) / 10000),
                    'longitude'     => 31.2357 + (rand(-500, 500) / 10000),
                    'is_default'    => true,
                ]);
            }
        }
    }
}
