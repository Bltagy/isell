<?php

namespace Database\Seeders;

use App\Models\Banner;
use Illuminate\Database\Seeder;

class BannerSeeder extends Seeder
{
    public function run(): void
    {
        $banners = [
            [
                'title_en' => 'Free Delivery Today!',
                'title_ar' => 'توصيل مجاني اليوم!',
                'image'    => 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=1200&q=80',
                'link_type' => 'none', 'sort_order' => 1,
            ],
            [
                'title_en' => '20% Off on All Burgers',
                'title_ar' => 'خصم 20% على البرجر',
                'image'    => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=1200&q=80',
                'link_type' => 'none', 'sort_order' => 2,
            ],
            [
                'title_en' => 'New Pizza Collection',
                'title_ar' => 'تشكيلة البيتزا الجديدة',
                'image'    => 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=1200&q=80',
                'link_type' => 'none', 'sort_order' => 3,
            ],
            [
                'title_en' => 'Weekend Special Deals',
                'title_ar' => 'عروض نهاية الأسبوع',
                'image'    => 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=1200&q=80',
                'link_type' => 'none', 'sort_order' => 4,
            ],
        ];

        foreach ($banners as $banner) {
            Banner::updateOrCreate(
                ['title_en' => $banner['title_en']],
                array_merge($banner, ['is_active' => true])
            );
        }
    }
}
