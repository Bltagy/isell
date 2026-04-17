<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Order;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/admin/dashboard
     */
    public function stats(): JsonResponse
    {
        $today = now()->toDateString();

        $todayOrders  = Order::whereDate('created_at', $today)->count();
        $todayRevenue = (int) Order::whereDate('created_at', $today)
            ->where('payment_status', 'paid')
            ->sum('total');

        $activeOrders   = Order::whereNotIn('status', ['delivered', 'cancelled', 'refunded'])->count();
        $pendingOrders  = Order::where('status', 'pending')->count();
        $totalCustomers = User::customers()->count();
        $activeDrivers  = User::drivers()->active()->count();

        // Last 30 days chart — cast revenue to int so JSON sends a number not a string
        $ordersChart = Order::select(
            DB::raw('DATE(created_at) as date'),
            DB::raw('COUNT(*) as orders'),
            DB::raw('CAST(SUM(total) AS UNSIGNED) as revenue')
        )
            ->where('created_at', '>=', now()->subDays(30))
            ->groupBy('date')
            ->orderBy('date')
            ->get()
            ->map(fn ($row) => [
                'date'    => $row->date,
                'orders'  => (int) $row->orders,
                'revenue' => (int) $row->revenue,
            ]);

        // Top 5 products
        $topProducts = DB::table('order_items')
            ->select('product_name_snapshot as name', DB::raw('SUM(quantity) as orders'))
            ->groupBy('product_name_snapshot')
            ->orderByDesc('orders')
            ->limit(5)
            ->get()
            ->map(fn ($row) => [
                'name'   => $row->name,
                'orders' => (int) $row->orders,
            ]);

        // 10 most recent orders for the dashboard table
        $recentOrders = Order::with('user')
            ->latest()
            ->limit(10)
            ->get()
            ->map(fn ($order) => [
                'id'            => $order->id,
                'order_number'  => (string) $order->id,
                'customer_name' => $order->user?->name ?? 'Guest',
                'items_count'   => $order->items()->count(),
                'total'         => (int) $order->total,
                'status'        => $order->status,
                'created_at'    => $order->created_at?->toISOString(),
            ]);

        return $this->success([
            'today_orders'      => $todayOrders,
            'today_revenue'     => $todayRevenue,
            'today_revenue_egp' => number_format($todayRevenue / 100, 2),
            'active_orders'     => $activeOrders,
            'pending_orders'    => $pendingOrders,
            'total_customers'   => $totalCustomers,
            'active_drivers'    => $activeDrivers,
            'orders_chart'      => $ordersChart,
            'top_products'      => $topProducts,
            'recent_orders'     => $recentOrders,
        ]);
    }

    /**
     * GET /api/v1/admin/analytics/revenue
     */
    public function revenueAnalytics(Request $request): JsonResponse
    {
        $from    = $request->input('from', now()->subDays(30)->toDateString());
        $to      = $request->input('to', now()->toDateString());
        $groupBy = $request->input('group_by', 'daily'); // daily|weekly|monthly

        $dateFormat = match ($groupBy) {
            'monthly' => '%Y-%m',
            'weekly'  => '%Y-%u',
            default   => '%Y-%m-%d',
        };

        $data = Order::select(
            DB::raw("DATE_FORMAT(created_at, '{$dateFormat}') as period"),
            DB::raw('COUNT(*) as orders_count'),
            DB::raw('SUM(total) as revenue')
        )
            ->whereDate('created_at', '>=', $from)
            ->whereDate('created_at', '<=', $to)
            ->groupBy('period')
            ->orderBy('period')
            ->get();

        return $this->success(['data' => $data, 'from' => $from, 'to' => $to]);
    }

    /**
     * GET /api/v1/admin/analytics/heatmap
     * Returns order volume by hour of day × day of week.
     */
    public function heatmap(): JsonResponse
    {
        $data = Order::select(
            DB::raw('DAYOFWEEK(created_at) as day_of_week'),
            DB::raw('HOUR(created_at) as hour'),
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', now()->subDays(90))
            ->groupBy('day_of_week', 'hour')
            ->orderBy('day_of_week')
            ->orderBy('hour')
            ->get();

        return $this->success($data);
    }
}
