<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class SuperAdminDashboardController extends Controller
{
    use ApiResponse;

    /**
     * GET /central/api/dashboard
     *
     * Returns:
     *  - total_active_tenants
     *  - mrr (sum of active subscription plan prices in piastres)
     *  - total_orders_approximate (sum across all tenant DBs)
     *  - new_signups_per_month (last 12 months)
     */
    public function index(): JsonResponse
    {
        // Total active tenants
        $totalActiveTenants = Tenant::active()->count();

        // MRR: sum of price_monthly for all active subscriptions
        $mrr = TenantSubscription::query()
            ->where('status', 'active')
            ->join('subscription_plans', 'tenant_subscriptions.plan_id', '=', 'subscription_plans.id')
            ->sum('subscription_plans.price_monthly');

        // Total orders (approximate) — query each tenant DB
        $totalOrders = $this->approximateTotalOrders();

        // New signups per month (last 12 months) from central DB
        $newSignupsPerMonth = Tenant::select(
            DB::raw("DATE_FORMAT(created_at, '%Y-%m') as month"),
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', now()->subMonths(12)->startOfMonth())
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        // Suspended tenants count
        $suspendedTenants = Tenant::suspended()->count();

        // Plans breakdown
        $plansBreakdown = SubscriptionPlan::withCount([
            'subscriptions as active_subscriptions_count' => fn ($q) => $q->where('status', 'active'),
        ])->active()->get(['id', 'name', 'price_monthly']);

        return $this->success([
            'total_active_tenants'   => $totalActiveTenants,
            'suspended_tenants'      => $suspendedTenants,
            'mrr_piastres'           => (int) $mrr,
            'mrr_egp'                => number_format($mrr / 100, 2),
            'total_orders_approx'    => $totalOrders,
            'new_signups_per_month'  => $newSignupsPerMonth,
            'plans_breakdown'        => $plansBreakdown,
        ]);
    }

    /**
     * Approximate total orders by querying each tenant's database.
     * Falls back gracefully if a tenant DB is unreachable.
     */
    private function approximateTotalOrders(): int
    {
        $total   = 0;
        $tenants = Tenant::active()->get();

        foreach ($tenants as $tenant) {
            try {
                tenancy()->initialize($tenant);
                $count = DB::table('orders')->count();
                $total += $count;
                tenancy()->end();
            } catch (\Throwable) {
                tenancy()->end();
                // Skip unreachable tenant DBs
            }
        }

        return $total;
    }
}
