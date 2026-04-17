<?php

namespace Database\Seeders;

use App\Models\Offer;
use Illuminate\Database\Seeder;

class OfferSeeder extends Seeder
{
    public function run(): void
    {
        $offers = [
            [
                'code'                => 'WELCOME20',
                'type'                => 'percentage',
                'value'               => 20,
                'min_order_amount'    => 5000,
                'max_discount_amount' => 5000,
                'applicable_to'       => 'all',
                'is_active'           => true,
                'start_date'          => now()->toDateString(),
                'end_date'            => now()->addMonths(3)->toDateString(),
            ],
            [
                'code'             => 'FREEDEL',
                'type'             => 'free_delivery',
                'value'            => 0,
                'min_order_amount' => 10000,
                'applicable_to'    => 'all',
                'is_active'        => true,
                'start_date'       => now()->toDateString(),
                'end_date'         => now()->addMonths(3)->toDateString(),
            ],
            [
                'code'             => 'SAVE15',
                'type'             => 'fixed',
                'value'            => 1500,
                'min_order_amount' => 8000,
                'applicable_to'    => 'all',
                'is_active'        => true,
                'start_date'       => now()->toDateString(),
                'end_date'         => now()->addMonths(3)->toDateString(),
            ],
        ];

        foreach ($offers as $offer) {
            Offer::updateOrCreate(['code' => $offer['code']], $offer);
        }
    }
}
