<?php

namespace Database\Seeders;

use App\Models\Category;
use App\Models\Product;
use App\Models\ProductOption;
use App\Models\ProductOptionItem;
use Illuminate\Database\Seeder;

class ProductSeeder extends Seeder
{
    public function run(): void
    {
        $burgers    = Category::where('name_en', 'Burgers')->first();
        $pizza      = Category::where('name_en', 'Pizza')->first();
        $drinks     = Category::where('name_en', 'Drinks')->first();
        $sandwiches = Category::where('name_en', 'Sandwiches')->first();
        $desserts   = Category::where('name_en', 'Desserts')->first();
        $salads     = Category::where('name_en', 'Salads')->first();
        $sides      = Category::where('name_en', 'Sides')->first();

        $products = [
            // ── Burgers ──────────────────────────────────────────────────
            ['category_id' => $burgers->id, 'name_en' => 'Classic Burger',        'name_ar' => 'برجر كلاسيك',          'price' => 8000,  'is_featured' => true,  'preparation_time_minutes' => 15, 'calories' => 520,
             'image' => 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80'],
            ['category_id' => $burgers->id, 'name_en' => 'Cheese Burger',         'name_ar' => 'تشيز برجر',            'price' => 9000,  'is_featured' => true,  'preparation_time_minutes' => 15, 'calories' => 580,
             'image' => 'https://images.unsplash.com/photo-1553979459-d2229ba7433b?w=800&q=80'],
            ['category_id' => $burgers->id, 'name_en' => 'Crispy Chicken Burger', 'name_ar' => 'برجر دجاج كريسبي',     'price' => 9500,  'is_featured' => false, 'preparation_time_minutes' => 18, 'calories' => 560,
             'image' => 'https://images.unsplash.com/photo-1606755962773-d324e0a13086?w=800&q=80'],
            ['category_id' => $burgers->id, 'name_en' => 'BBQ Burger',            'name_ar' => 'برجر باربيكيو',        'price' => 10000, 'is_featured' => false, 'preparation_time_minutes' => 18, 'calories' => 620,
             'image' => 'https://images.unsplash.com/photo-1594212699903-ec8a3eca50f5?w=800&q=80'],
            ['category_id' => $burgers->id, 'name_en' => 'Double Smash Burger',   'name_ar' => 'دبل سماش برجر',        'price' => 13000, 'is_featured' => true,  'preparation_time_minutes' => 20, 'calories' => 780,
             'image' => 'https://images.unsplash.com/photo-1571091718767-18b5b1457add?w=800&q=80'],
            ['category_id' => $burgers->id, 'name_en' => 'Mushroom Swiss Burger', 'name_ar' => 'برجر مشروم سويسري',    'price' => 11000, 'is_featured' => false, 'preparation_time_minutes' => 18, 'calories' => 640,
             'image' => 'https://images.unsplash.com/photo-1550547660-d9450f859349?w=800&q=80'],
            ['category_id' => $burgers->id, 'name_en' => 'Spicy Jalapeño Burger', 'name_ar' => 'برجر هالابينيو حار',   'price' => 10500, 'is_featured' => false, 'preparation_time_minutes' => 18, 'calories' => 600,
             'image' => 'https://images.unsplash.com/photo-1561758033-d89a9ad46330?w=800&q=80'],

            // ── Pizza ────────────────────────────────────────────────────
            ['category_id' => $pizza->id, 'name_en' => 'Pepperoni Pizza',         'name_ar' => 'بيتزا بيبروني',        'price' => 14000, 'is_featured' => true,  'preparation_time_minutes' => 20, 'calories' => 720,
             'image' => 'https://images.unsplash.com/photo-1628840042765-356cda07504e?w=800&q=80'],
            ['category_id' => $pizza->id, 'name_en' => 'Four Cheese Pizza',       'name_ar' => 'بيتزا أربع جبن',       'price' => 15000, 'is_featured' => false, 'preparation_time_minutes' => 20, 'calories' => 800,
             'image' => 'https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800&q=80'],
            ['category_id' => $pizza->id, 'name_en' => 'BBQ Chicken Pizza',       'name_ar' => 'بيتزا دجاج باربيكيو',  'price' => 13500, 'is_featured' => false, 'preparation_time_minutes' => 20, 'calories' => 680,
             'image' => 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=800&q=80'],
            ['category_id' => $pizza->id, 'name_en' => 'Veggie Pizza',            'name_ar' => 'بيتزا خضار',           'price' => 12000, 'is_featured' => false, 'preparation_time_minutes' => 18, 'calories' => 580,
             'image' => 'https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&q=80'],
            ['category_id' => $pizza->id, 'name_en' => 'Meat Lovers Pizza',       'name_ar' => 'بيتزا عشاق اللحوم',    'price' => 16000, 'is_featured' => true,  'preparation_time_minutes' => 22, 'calories' => 860,
             'image' => 'https://images.unsplash.com/photo-1534308983496-4fabb1a015ee?w=800&q=80'],
            ['category_id' => $pizza->id, 'name_en' => 'Margherita Pizza',        'name_ar' => 'بيتزا مارغريتا',       'price' => 11000, 'is_featured' => false, 'preparation_time_minutes' => 18, 'calories' => 540,
             'image' => 'https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=800&q=80'],

            // ── Drinks ───────────────────────────────────────────────────
            ['category_id' => $drinks->id, 'name_en' => 'Fresh Orange Juice',     'name_ar' => 'عصير برتقال طازج',     'price' => 3500,  'is_featured' => false, 'preparation_time_minutes' => 5,  'calories' => 120,
             'image' => 'https://images.unsplash.com/photo-1621506289937-a8e4df240d0b?w=800&q=80'],
            ['category_id' => $drinks->id, 'name_en' => 'Mango Juice',            'name_ar' => 'عصير مانجو',           'price' => 4000,  'is_featured' => false, 'preparation_time_minutes' => 5,  'calories' => 150,
             'image' => 'https://images.unsplash.com/photo-1546173159-315724a31696?w=800&q=80'],
            ['category_id' => $drinks->id, 'name_en' => 'Lemon Mint',             'name_ar' => 'ليمون بالنعناع',       'price' => 3500,  'is_featured' => true,  'preparation_time_minutes' => 5,  'calories' => 80,
             'image' => 'https://images.unsplash.com/photo-1556679343-c7306c1976bc?w=800&q=80'],
            ['category_id' => $drinks->id, 'name_en' => 'Soft Drink',             'name_ar' => 'مشروب غازي',           'price' => 2000,  'is_featured' => false, 'preparation_time_minutes' => 2,  'calories' => 140,
             'image' => 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=800&q=80'],
            ['category_id' => $drinks->id, 'name_en' => 'Water Bottle',           'name_ar' => 'زجاجة مياه',           'price' => 1000,  'is_featured' => false, 'preparation_time_minutes' => 1,  'calories' => 0,
             'image' => 'https://images.unsplash.com/photo-1548839140-29a749e1cf4d?w=800&q=80'],
            ['category_id' => $drinks->id, 'name_en' => 'Strawberry Smoothie',    'name_ar' => 'سموذي فراولة',         'price' => 4500,  'is_featured' => true,  'preparation_time_minutes' => 5,  'calories' => 180,
             'image' => 'https://images.unsplash.com/photo-1553530666-ba11a7da3888?w=800&q=80'],
            ['category_id' => $drinks->id, 'name_en' => 'Iced Coffee',            'name_ar' => 'قهوة مثلجة',           'price' => 3000,  'is_featured' => false, 'preparation_time_minutes' => 3,  'calories' => 90,
             'image' => 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=800&q=80'],

            // ── Sandwiches ───────────────────────────────────────────────
            ['category_id' => $sandwiches->id, 'name_en' => 'Club Sandwich',      'name_ar' => 'كلوب سندوتش',          'price' => 7500,  'is_featured' => true,  'preparation_time_minutes' => 12, 'calories' => 480,
             'image' => 'https://images.unsplash.com/photo-1528735602780-2552fd46c7af?w=800&q=80'],
            ['category_id' => $sandwiches->id, 'name_en' => 'Grilled Chicken Wrap','name_ar' => 'راب دجاج مشوي',       'price' => 8000,  'is_featured' => false, 'preparation_time_minutes' => 12, 'calories' => 420,
             'image' => 'https://images.unsplash.com/photo-1626700051175-6818013e1d4f?w=800&q=80'],
            ['category_id' => $sandwiches->id, 'name_en' => 'Tuna Sandwich',      'name_ar' => 'سندوتش تونة',          'price' => 6500,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 380,
             'image' => 'https://images.unsplash.com/photo-1509722747041-616f39b57569?w=800&q=80'],
            ['category_id' => $sandwiches->id, 'name_en' => 'Shawarma Chicken',   'name_ar' => 'شاورما دجاج',          'price' => 7000,  'is_featured' => true,  'preparation_time_minutes' => 10, 'calories' => 450,
             'image' => 'https://images.unsplash.com/photo-1599487488170-d11ec9c172f0?w=800&q=80'],
            ['category_id' => $sandwiches->id, 'name_en' => 'Shawarma Meat',      'name_ar' => 'شاورما لحم',           'price' => 9000,  'is_featured' => false, 'preparation_time_minutes' => 10, 'calories' => 520,
             'image' => 'https://images.unsplash.com/photo-1529006557810-274b9b2fc783?w=800&q=80'],

            // ── Desserts ─────────────────────────────────────────────────
            ['category_id' => $desserts->id, 'name_en' => 'Chocolate Lava Cake',  'name_ar' => 'كيك لافا شوكولاتة',   'price' => 5500,  'is_featured' => true,  'preparation_time_minutes' => 10, 'calories' => 420,
             'image' => 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?w=800&q=80'],
            ['category_id' => $desserts->id, 'name_en' => 'Cheesecake Slice',     'name_ar' => 'شريحة تشيز كيك',      'price' => 4500,  'is_featured' => false, 'preparation_time_minutes' => 5,  'calories' => 380,
             'image' => 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=800&q=80'],
            ['category_id' => $desserts->id, 'name_en' => 'Kunafa',               'name_ar' => 'كنافة',               'price' => 5000,  'is_featured' => true,  'preparation_time_minutes' => 8,  'calories' => 460,
             'image' => 'https://images.unsplash.com/photo-1579888944880-d98341245702?w=800&q=80'],
            ['category_id' => $desserts->id, 'name_en' => 'Om Ali',               'name_ar' => 'أم علي',              'price' => 4000,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 400,
             'image' => 'https://images.unsplash.com/photo-1551024506-0bccd828d307?w=800&q=80'],

            // ── Salads ───────────────────────────────────────────────────
            ['category_id' => $salads->id, 'name_en' => 'Caesar Salad',           'name_ar' => 'سلطة سيزر',           'price' => 6000,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 280,
             'image' => 'https://images.unsplash.com/photo-1546793665-c74683f339c1?w=800&q=80'],
            ['category_id' => $salads->id, 'name_en' => 'Greek Salad',            'name_ar' => 'سلطة يونانية',        'price' => 5500,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 220,
             'image' => 'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=800&q=80'],
            ['category_id' => $salads->id, 'name_en' => 'Fattoush',               'name_ar' => 'فتوش',                'price' => 4500,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 180,
             'image' => 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80'],

            // ── Sides ────────────────────────────────────────────────────
            ['category_id' => $sides->id, 'name_en' => 'French Fries',            'name_ar' => 'بطاطس مقلية',         'price' => 3000,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 320,
             'image' => 'https://images.unsplash.com/photo-1573080496219-bb080dd4f877?w=800&q=80'],
            ['category_id' => $sides->id, 'name_en' => 'Onion Rings',             'name_ar' => 'حلقات بصل',           'price' => 3500,  'is_featured' => false, 'preparation_time_minutes' => 8,  'calories' => 280,
             'image' => 'https://images.unsplash.com/photo-1639024471283-03518883512d?w=800&q=80'],
            ['category_id' => $sides->id, 'name_en' => 'Coleslaw',                'name_ar' => 'كول سلو',             'price' => 2500,  'is_featured' => false, 'preparation_time_minutes' => 3,  'calories' => 150,
             'image' => 'https://images.unsplash.com/photo-1621996346565-e3dbc646d9a9?w=800&q=80'],
            ['category_id' => $sides->id, 'name_en' => 'Garlic Bread',            'name_ar' => 'خبز بالثوم',          'price' => 2000,  'is_featured' => false, 'preparation_time_minutes' => 5,  'calories' => 200,
             'image' => 'https://images.unsplash.com/photo-1619535860434-cf9b902a0e9e?w=800&q=80'],
        ];

        foreach ($products as $i => $data) {
            $product = Product::updateOrCreate(
                ['name_en' => $data['name_en']],
                array_merge($data, ['is_available' => true, 'sort_order' => $i + 1])
            );

            if ($product->options()->count() > 0) continue;

            if (in_array($product->category_id, [$burgers->id, $pizza->id])) {
                $sizeOption = ProductOption::create([
                    'product_id' => $product->id, 'name_en' => 'Size', 'name_ar' => 'الحجم',
                    'type' => 'single', 'is_required' => true, 'max_selections' => 1,
                ]);
                ProductOptionItem::insert([
                    ['option_id' => $sizeOption->id, 'name_en' => 'Single', 'name_ar' => 'سينجل', 'extra_price' => 0,    'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $sizeOption->id, 'name_en' => 'Medium', 'name_ar' => 'وسط',   'extra_price' => 2000, 'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $sizeOption->id, 'name_en' => 'Large',  'name_ar' => 'كبير',  'extra_price' => 4000, 'created_at' => now(), 'updated_at' => now()],
                ]);
            }

            if ($product->category_id === $burgers->id) {
                $extrasOption = ProductOption::create([
                    'product_id' => $product->id, 'name_en' => 'Extras', 'name_ar' => 'إضافات',
                    'type' => 'multiple', 'is_required' => false, 'max_selections' => 3,
                ]);
                ProductOptionItem::insert([
                    ['option_id' => $extrasOption->id, 'name_en' => 'Extra Cheese', 'name_ar' => 'جبن إضافي',  'extra_price' => 1000, 'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $extrasOption->id, 'name_en' => 'Extra Sauce',  'name_ar' => 'صوص إضافي',  'extra_price' => 500,  'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $extrasOption->id, 'name_en' => 'Jalapeños',    'name_ar' => 'هالابينيو',  'extra_price' => 750,  'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $extrasOption->id, 'name_en' => 'Bacon',        'name_ar' => 'بيكون',      'extra_price' => 1500, 'created_at' => now(), 'updated_at' => now()],
                ]);
            }

            if ($product->name_en === 'French Fries') {
                $sizeOption = ProductOption::create([
                    'product_id' => $product->id, 'name_en' => 'Size', 'name_ar' => 'الحجم',
                    'type' => 'single', 'is_required' => true, 'max_selections' => 1,
                ]);
                ProductOptionItem::insert([
                    ['option_id' => $sizeOption->id, 'name_en' => 'Small',  'name_ar' => 'صغير', 'extra_price' => 0,    'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $sizeOption->id, 'name_en' => 'Medium', 'name_ar' => 'وسط',  'extra_price' => 1000, 'created_at' => now(), 'updated_at' => now()],
                    ['option_id' => $sizeOption->id, 'name_en' => 'Large',  'name_ar' => 'كبير', 'extra_price' => 2000, 'created_at' => now(), 'updated_at' => now()],
                ]);
            }
        }
    }
}
