<?php

namespace App\Http\Middleware;

use App\Models\TenantSetting;
use Closure;
use Illuminate\Http\Request;

class EnsureTenantIsActive
{
    public function handle(Request $request, Closure $next): mixed
    {
        $tenant = tenancy()->tenant;

        if (!$tenant) {
            return response()->json([
                'success' => false,
                'message' => 'Tenant not found.',
            ], 404);
        }

        // Check maintenance_mode TenantSetting
        $maintenanceSetting = TenantSetting::where('key', 'maintenance_mode')->first();
        $isMaintenanceMode  = $maintenanceSetting && filter_var($maintenanceSetting->value, FILTER_VALIDATE_BOOLEAN);

        if ($isMaintenanceMode) {
            $locale  = app()->getLocale();
            $msgKey  = $locale === 'ar' ? 'maintenance_message_ar' : 'maintenance_message_en';
            $message = TenantSetting::where('key', $msgKey)->value('value')
                ?? 'We are currently under maintenance. Please try again later.';

            return response()->json([
                'success' => false,
                'message' => $message,
            ], 503);
        }

        return $next($request);
    }
}
