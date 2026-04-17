<?php

namespace Database\Seeders;

use App\Models\Category;
use Illuminate\Database\Seeder;

class CategorySeeder extends Seeder
{
    public function run(): void
    {
        $categories = [
            ['name_en' => 'Burgers',    'name_ar' => 'برجر',        'sort_order' => 1,
             'image' => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=400&q=80'],
            ['name_en' => 'Pizza',      'name_ar' => 'بيتزا',       'sort_order' => 2,
             'image' => 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400&q=80'],
            ['name_en' => 'Drinks',     'name_ar' => 'مشروبات',     'sort_order' => 3,
             'image' => 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=400&q=80'],
            ['name_en' => 'Sandwiches', 'name_ar' => 'سندوتشات',    'sort_order' => 4,
             'image' => 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=400&q=80'],
            ['name_en' => 'Desserts',   'name_ar' => 'حلويات',      'sort_order' => 5,
             'image' => 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=400&q=80'],
            ['name_en' => 'Salads',     'name_ar' => 'سلطات',       'sort_order' => 6,
             'image' => 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400&q=80'],
            ['name_en' => 'Sides',      'name_ar' => 'مقبلات',      'sort_order' => 7,
             'image' => 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=400&q=80'],
        ];

        foreach ($categories as $cat) {
            Category::updateOrCreate(
                ['name_en' => $cat['name_en']],
                array_merge($cat, ['is_active' => true])
            );
        }
    }
}
