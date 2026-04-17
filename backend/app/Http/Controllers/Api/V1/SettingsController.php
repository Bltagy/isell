<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Models\TenantSetting;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Cache;

class SettingsController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/settings/app-config
     * First call Flutter makes on launch — cached 5 minutes.
     */
    public function appConfig(): JsonResponse
    {
        $config = Cache::remember('app_config', 300, function () {
            $sensitiveKeys = ['kashier_api_key', 'fcm_server_key'];

            return TenantSetting::whereNotIn('key', $sensitiveKeys)
                ->get()
                ->mapWithKeys(fn($s) => [$s->key => $s->casted_value]);
        });

        return $this->success($config);
    }

    /**
     * GET /api/v1/settings/about
     * Returns app identity, description, contact info and legal links.
     * Content is managed via POST /api/v1/admin/settings/batch-update.
     */
    public function about(): JsonResponse
    {
        $keys = [
            'app_name_en', 'app_name_ar',
            'about_us_en', 'about_us_ar',
            'contact_email', 'contact_phone',
            'privacy_policy_en', 'privacy_policy_ar',
            'terms_en', 'terms_ar',
        ];

        $s = TenantSetting::whereIn('key', $keys)
            ->get()
            ->mapWithKeys(fn($row) => [$row->key => $row->casted_value]);

        return $this->success([
            'app_name'           => $s['app_name_en'] ?? $s['app_name_ar'] ?? 'Food App',
            'description_en'     => $s['about_us_en'] ?? '',
            'description_ar'     => $s['about_us_ar'] ?? '',
            'version'            => config('app.version', '1.0.0'),
            'contact_email'      => $s['contact_email'] ?? '',
            'contact_phone'      => $s['contact_phone'] ?? '',
            'privacy_policy_en'  => $s['privacy_policy_en'] ?? '',
            'privacy_policy_ar'  => $s['privacy_policy_ar'] ?? '',
            'terms_en'           => $s['terms_en'] ?? '',
            'terms_ar'           => $s['terms_ar'] ?? '',
        ]);
    }

    /**
     * GET /api/v1/settings/help
     * Returns support contacts and FAQ items.
     * Content is managed via POST /api/v1/admin/settings/batch-update.
     */
    public function help(): JsonResponse
    {
        $keys = [
            'contact_email', 'contact_phone',
            'help_whatsapp', 'help_faq',
        ];

        $s = TenantSetting::whereIn('key', $keys)
            ->get()
            ->mapWithKeys(fn($row) => [$row->key => $row->casted_value]);

        $faq = $s['help_faq'] ?? [];
        if (is_string($faq)) {
            $faq = json_decode($faq, true) ?? [];
        }

        return $this->success([
            'support_email' => $s['contact_email'] ?? '',
            'support_phone' => $s['contact_phone'] ?? '',
            'whatsapp'      => $s['help_whatsapp'] ?? '',
            'faq'           => $faq,
        ]);
    }
}
