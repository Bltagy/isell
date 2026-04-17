<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\TenantSetting;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Storage;

class AdminSettingsController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/admin/settings
     */
    public function index(): JsonResponse
    {
        $settings = TenantSetting::all()->mapWithKeys(fn($s) => [$s->key => [
            'value' => $s->casted_value,
            'type'  => $s->type,
        ]]);

        return $this->success($settings);
    }

    /**
     * POST /api/v1/admin/settings/batch-update
     */
    public function batchUpdate(Request $request): JsonResponse
    {
        $request->validate(['settings' => 'required|array']);

        foreach ($request->settings as $key => $value) {
            [$storedValue, $type] = $this->resolveValueAndType($value);
            TenantSetting::updateOrCreate(
                ['key' => $key],
                ['value' => $storedValue, 'type' => $type]
            );
        }

        Cache::forget('app_config');

        return $this->success(null, 'Settings updated');
    }

    /**
     * Detect the correct storage type and serialise the value accordingly.
     */
    private function resolveValueAndType(mixed $value): array
    {
        if (is_bool($value)) {
            return [$value ? '1' : '0', 'boolean'];
        }

        if (is_array($value) || is_object($value)) {
            return [json_encode($value), 'json'];
        }

        return [(string) $value, 'string'];
    }

    /**
     * GET /api/v1/admin/settings/faq
     */
    public function getFaq(): JsonResponse
    {
        $setting = TenantSetting::where('key', 'help_faq')->first();
        $faq = [];

        if ($setting) {
            $raw = $setting->casted_value;
            $faq = is_array($raw) ? $raw : (json_decode($raw, true) ?? []);
        }

        return $this->success($faq);
    }

    /**
     * POST /api/v1/admin/settings/faq
     * Body: { items: [ { question_en, question_ar, answer_en, answer_ar } ] }
     */
    public function saveFaq(Request $request): JsonResponse
    {
        $request->validate([
            'items'                   => 'required|array',
            'items.*.question_en'     => 'required|string|max:500',
            'items.*.question_ar'     => 'required|string|max:500',
            'items.*.answer_en'       => 'required|string|max:2000',
            'items.*.answer_ar'       => 'required|string|max:2000',
        ]);

        TenantSetting::updateOrCreate(
            ['key' => 'help_faq'],
            ['value' => json_encode(array_values($request->items)), 'type' => 'json']
        );

        Cache::forget('app_config');

        return $this->success(null, 'FAQ saved');
    }

    /**
     * POST /api/v1/admin/settings/upload-image
     */
    public function uploadImage(Request $request): JsonResponse
    {
        $request->validate([
            'key'   => 'required|string|in:app_logo,dashboard_logo,app_splash_image',
            'image' => 'required|image|mimes:jpeg,png,webp,gif|max:5120',
        ]);

        $file     = $request->file('image');
        $filename = $file->hashName();
        $destDir  = base_path('storage/app/public/settings');

        if (! is_dir($destDir)) {
            mkdir($destDir, 0755, true);
        }

        $file->move($destDir, $filename);

        // Store a relative path — the frontend prepends the API base URL.
        // This avoids stale absolute URLs when the IP or port changes.
        $relativePath = '/storage/settings/' . $filename;

        // Map upload key → the setting key the frontend reads
        $settingKey = match ($request->key) {
            'app_logo'        => 'logo_url',
            'dashboard_logo'  => 'dashboard_logo_url',
            default           => $request->key,
        };

        TenantSetting::updateOrCreate(
            ['key' => $settingKey],
            ['value' => $relativePath, 'type' => 'image']
        );

        // Also clean up the old wrong-key record if it exists
        TenantSetting::where('key', $request->key)->delete();

        Cache::forget('app_config');

        // Return the full URL so the frontend can display it immediately
        $fullUrl = rtrim($request->getSchemeAndHttpHost(), '/') . $relativePath;

        return $this->success(['url' => $fullUrl], 'Image uploaded');
    }
}
