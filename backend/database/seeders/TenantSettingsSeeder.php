<?php

namespace Database\Seeders;

use App\Models\TenantSetting;
use Illuminate\Database\Seeder;

class TenantSettingsSeeder extends Seeder
{
    public function run(): void
    {
        $settings = [
            // App Identity
            ['key' => 'app_name_en',        'value' => 'Food App',          'type' => 'string'],
            ['key' => 'app_name_ar',        'value' => 'تطبيق الطعام',      'type' => 'string'],
            ['key' => 'app_logo',           'value' => '',                  'type' => 'image'],
            ['key' => 'splash_screen_image','value' => '',                  'type' => 'image'],
            ['key' => 'app_splash_image',   'value' => '',                  'type' => 'image'],

            // Colors
            ['key' => 'primary_color',      'value' => '#FF6B35',           'type' => 'color'],
            ['key' => 'secondary_color',    'value' => '#FF8C42',           'type' => 'color'],
            ['key' => 'accent_color',       'value' => '#FFA726',           'type' => 'color'],
            ['key' => 'background_color',   'value' => '#FFFFFF',           'type' => 'color'],
            ['key' => 'text_color',         'value' => '#212121',           'type' => 'color'],
            ['key' => 'font_family',        'value' => 'Cairo',             'type' => 'string'],

            // Pricing
            ['key' => 'delivery_fee_egp',       'value' => '2000',  'type' => 'string'], // piastres
            ['key' => 'min_order_amount_egp',   'value' => '5000',  'type' => 'string'], // piastres
            ['key' => 'tax_percentage',         'value' => '14',    'type' => 'string'],

            // Working Hours
            ['key' => 'working_hours_json', 'value' => json_encode([
                'saturday'  => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
                'sunday'    => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
                'monday'    => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
                'tuesday'   => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
                'wednesday' => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
                'thursday'  => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
                'friday'    => ['open' => '09:00', 'close' => '23:00', 'is_open' => true],
            ]), 'type' => 'json'],

            // Contact
            ['key' => 'contact_phone',  'value' => '+201000000000', 'type' => 'string'],
            ['key' => 'contact_email',  'value' => 'info@foodapp.com', 'type' => 'string'],

            // Content
            ['key' => 'about_us_en',            'value' => 'We deliver the best food in Egypt.', 'type' => 'string'],
            ['key' => 'about_us_ar',            'value' => 'نوصل أفضل طعام في مصر.',             'type' => 'string'],
            ['key' => 'privacy_policy_en',      'value' => 'Privacy policy content here.',       'type' => 'string'],
            ['key' => 'privacy_policy_ar',      'value' => 'محتوى سياسة الخصوصية هنا.',          'type' => 'string'],
            ['key' => 'terms_en',               'value' => 'Terms and conditions content here.', 'type' => 'string'],
            ['key' => 'terms_ar',               'value' => 'محتوى الشروط والأحكام هنا.',         'type' => 'string'],

            // Payment
            ['key' => 'kashier_merchant_id',    'value' => '', 'type' => 'string'],
            ['key' => 'kashier_api_key',        'value' => '', 'type' => 'string'],
            ['key' => 'fcm_server_key',         'value' => '', 'type' => 'string'],

            // Delivery
            ['key' => 'max_delivery_radius_km', 'value' => '10',    'type' => 'string'],
            ['key' => 'currency',               'value' => 'EGP',   'type' => 'string'],
            ['key' => 'default_language',       'value' => 'ar',    'type' => 'string'],

            // Maintenance
            ['key' => 'maintenance_mode',           'value' => 'false',                         'type' => 'boolean'],
            ['key' => 'maintenance_message_en',     'value' => 'We are under maintenance.',      'type' => 'string'],
            ['key' => 'maintenance_message_ar',     'value' => 'نحن في وضع الصيانة.',            'type' => 'string'],

            // App Store Links
            ['key' => 'app_store_url',  'value' => '', 'type' => 'string'],
            ['key' => 'play_store_url', 'value' => '', 'type' => 'string'],

            // Help & Support
            ['key' => 'help_whatsapp', 'value' => '', 'type' => 'string'],
            ['key' => 'help_faq', 'value' => json_encode([
                [
                    'question_en' => 'How do I track my order?',
                    'question_ar' => 'كيف أتتبع طلبي؟',
                    'answer_en'   => 'Go to Orders → tap your order → tap "Track Order" to see real-time status.',
                    'answer_ar'   => 'اذهب إلى الطلبات → اضغط على طلبك → اضغط "تتبع الطلب" لرؤية الحالة الآنية.',
                ],
                [
                    'question_en' => 'How do I cancel an order?',
                    'question_ar' => 'كيف أُلغي طلبي؟',
                    'answer_en'   => 'You can cancel an order from the order details page as long as it has not been confirmed yet.',
                    'answer_ar'   => 'يمكنك إلغاء الطلب من صفحة تفاصيل الطلب طالما لم يتم تأكيده بعد.',
                ],
                [
                    'question_en' => 'What payment methods are accepted?',
                    'question_ar' => 'ما طرق الدفع المقبولة؟',
                    'answer_en'   => 'We accept cash on delivery and card payments via Kashier.',
                    'answer_ar'   => 'نقبل الدفع عند الاستلام والدفع بالبطاقة عبر Kashier.',
                ],
                [
                    'question_en' => 'How long does delivery take?',
                    'question_ar' => 'كم يستغرق التوصيل؟',
                    'answer_en'   => 'Delivery typically takes 30–60 minutes depending on your location and order volume.',
                    'answer_ar'   => 'يستغرق التوصيل عادةً 30–60 دقيقة حسب موقعك وحجم الطلبات.',
                ],
                [
                    'question_en' => 'Can I change my delivery address after placing an order?',
                    'question_ar' => 'هل يمكنني تغيير عنوان التوصيل بعد تقديم الطلب؟',
                    'answer_en'   => 'Please contact support immediately. Address changes are only possible before the order is confirmed.',
                    'answer_ar'   => 'تواصل مع الدعم فوراً. تغيير العنوان ممكن فقط قبل تأكيد الطلب.',
                ],
            ]), 'type' => 'json'],
        ];

        foreach ($settings as $setting) {
            TenantSetting::updateOrCreate(['key' => $setting['key']], $setting);
        }
    }
}
