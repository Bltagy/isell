<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;

class EnsureSubscriptionActive
{
    public function handle(Request $request, Closure $next): mixed
    {
        $tenant = tenancy()->tenant;

        if (!$tenant) {
            return $next($request);
        }

        $subscription = $tenant->activeSubscription;

        // No active subscription or end_date has passed → 402
        if (!$subscription || $subscription->end_date?->isPast()) {
            return response()->json([
                'success' => false,
                'message' => 'Your subscription has expired. Please renew to continue using the service.',
            ], 402);
        }

        return $next($request);
    }
}
