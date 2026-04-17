<?php

namespace App\Http\Controllers\Central;

use App\Http\Controllers\Controller;
use App\Models\Domain;
use App\Models\SubscriptionPlan;
use App\Models\Tenant;
use App\Models\TenantSubscription;
use App\Services\TenantService;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class CentralDashboardController extends Controller
{
    public function __construct(private readonly TenantService $tenantService) {}

    // ── Overview ──────────────────────────────────────────────

    public function index()
    {
        $stats = [
            'total_tenants'     => Tenant::withTrashed()->count(),
            'active_tenants'    => Tenant::active()->count(),
            'suspended_tenants' => Tenant::suspended()->count(),
            'total_plans'       => SubscriptionPlan::count(),
            'mrr'               => TenantSubscription::where('status', 'active')
                ->join('subscription_plans', 'tenant_subscriptions.plan_id', '=', 'subscription_plans.id')
                ->sum('subscription_plans.price_monthly'),
        ];

        $recentTenants = Tenant::withTrashed()
            ->with(['primaryDomain', 'activeSubscription.plan'])
            ->latest()
            ->limit(5)
            ->get();

        $signupsChart = Tenant::select(
            DB::raw("DATE_FORMAT(created_at, '%Y-%m') as month"),
            DB::raw('COUNT(*) as count')
        )
            ->where('created_at', '>=', now()->subMonths(6)->startOfMonth())
            ->groupBy('month')
            ->orderBy('month')
            ->get();

        $plansBreakdown = SubscriptionPlan::withCount([
            'subscriptions as active_count' => fn ($q) => $q->where('status', 'active'),
        ])->get();

        return view('central.dashboard', compact('stats', 'recentTenants', 'signupsChart', 'plansBreakdown'));
    }

    // ── Tenants ───────────────────────────────────────────────

    public function tenants(Request $request)
    {
        $query = Tenant::withTrashed()->with(['primaryDomain', 'activeSubscription.plan']);

        if ($search = $request->input('search')) {
            $query->where(fn ($q) => $q->where('name', 'like', "%{$search}%")
                ->orWhere('email', 'like', "%{$search}%")
                ->orWhere('id', 'like', "%{$search}%"));
        }

        if ($status = $request->input('status')) {
            if ($status === 'deleted') {
                $query->onlyTrashed();
            } else {
                $query->where('status', $status);
            }
        }

        $tenants = $query->latest()->paginate(15)->withQueryString();

        return view('central.tenants.index', compact('tenants'));
    }

    public function createTenant()
    {
        $plans = SubscriptionPlan::active()->get();
        return view('central.tenants.create', compact('plans'));
    }

    public function storeTenant(Request $request)
    {
        $data = $request->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email|unique:tenants,email',
            'slug'  => 'nullable|string|alpha_dash|max:63|unique:domains,domain',
        ]);

        $tenant = $this->tenantService->provision($data);

        return redirect()->route('central.tenants')
            ->with('success', "Tenant \"{$tenant->name}\" provisioned successfully.");
    }

    public function showTenant(string $id)
    {
        $tenant = Tenant::withTrashed()
            ->with(['domains', 'subscriptions.plan'])
            ->findOrFail($id);

        $plans = SubscriptionPlan::active()->get();

        return view('central.tenants.show', compact('tenant', 'plans'));
    }

    public function suspendTenant(string $id)
    {
        $tenant = Tenant::findOrFail($id);
        $tenant->update(['status' => 'suspended']);

        return back()->with('success', "Tenant \"{$tenant->name}\" suspended.");
    }

    public function activateTenant(string $id)
    {
        $tenant = Tenant::findOrFail($id);
        $tenant->update(['status' => 'active']);

        return back()->with('success', "Tenant \"{$tenant->name}\" activated.");
    }

    public function destroyTenant(string $id)
    {
        $tenant = Tenant::findOrFail($id);
        $tenant->delete();

        return redirect()->route('central.tenants')
            ->with('success', "Tenant \"{$tenant->name}\" deleted.");
    }

    public function assignPlan(Request $request, string $id)
    {
        $data = $request->validate([
            'plan_id'    => 'required|exists:subscription_plans,id',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
        ]);

        $tenant = Tenant::findOrFail($id);

        // Cancel existing active subscriptions
        TenantSubscription::where('tenant_id', $id)->where('status', 'active')
            ->update(['status' => 'cancelled']);

        TenantSubscription::create([
            'tenant_id'  => $id,
            'plan_id'    => $data['plan_id'],
            'start_date' => $data['start_date'],
            'end_date'   => $data['end_date'],
            'status'     => 'active',
        ]);

        return back()->with('success', 'Subscription assigned successfully.');
    }

    public function updateSubscription(Request $request, string $tenantId, int $subId)
    {
        $data = $request->validate([
            'plan_id'    => 'required|exists:subscription_plans,id',
            'start_date' => 'required|date',
            'end_date'   => 'required|date|after:start_date',
            'status'     => 'required|in:active,expired,cancelled',
        ]);

        $sub = TenantSubscription::where('tenant_id', $tenantId)->findOrFail($subId);

        if ($data['status'] === 'active') {
            TenantSubscription::where('tenant_id', $tenantId)
                ->where('id', '!=', $subId)
                ->where('status', 'active')
                ->update(['status' => 'cancelled']);
        }

        $sub->update($data);

        return back()->with('success', 'Subscription updated.');
    }

    public function destroySubscription(string $tenantId, int $subId)
    {
        $sub = TenantSubscription::where('tenant_id', $tenantId)->findOrFail($subId);
        $sub->delete();

        return back()->with('success', 'Subscription removed.');
    }

    // ── Tenant Info Update ────────────────────────────────────

    public function updateTenant(Request $request, string $id)
    {
        $tenant = Tenant::findOrFail($id);

        $data = $request->validate([
            'name'   => 'required|string|max:255',
            'email'  => ['required', 'email', Rule::unique('tenants', 'email')->ignore($id)],
            'status' => 'required|in:active,suspended',
        ]);

        $tenant->update($data);

        return back()->with('success', 'Tenant info updated.');
    }

    // ── Domain Management ─────────────────────────────────────

    public function storeDomain(Request $request, string $tenantId)
    {
        $request->validate([
            'domain'     => 'required|string|max:255|unique:domains,domain',
            'is_primary' => 'boolean',
        ]);

        $tenant = Tenant::findOrFail($tenantId);

        if ($request->boolean('is_primary')) {
            $tenant->domains()->update(['is_primary' => false]);
        }

        $tenant->domains()->create([
            'domain'     => $request->input('domain'),
            'is_primary' => $request->boolean('is_primary'),
        ]);

        return back()->with('success', 'Domain added.');
    }

    public function updateDomain(Request $request, string $tenantId, int $domainId)
    {
        $domain = Domain::where('tenant_id', $tenantId)->findOrFail($domainId);

        $request->validate([
            'domain'     => ['required', 'string', 'max:255', Rule::unique('domains', 'domain')->ignore($domainId)],
            'is_primary' => 'boolean',
        ]);

        if ($request->boolean('is_primary')) {
            Domain::where('tenant_id', $tenantId)->update(['is_primary' => false]);
        }

        $domain->update([
            'domain'     => $request->input('domain'),
            'is_primary' => $request->boolean('is_primary'),
        ]);

        return back()->with('success', 'Domain updated.');
    }

    public function setPrimaryDomain(string $tenantId, int $domainId)
    {
        Domain::where('tenant_id', $tenantId)->update(['is_primary' => false]);
        Domain::where('tenant_id', $tenantId)->where('id', $domainId)->update(['is_primary' => true]);

        return back()->with('success', 'Primary domain updated.');
    }

    public function destroyDomain(string $tenantId, int $domainId)
    {
        $domain = Domain::where('tenant_id', $tenantId)->findOrFail($domainId);

        if ($domain->is_primary) {
            return back()->with('error', 'Cannot delete the primary domain. Set another domain as primary first.');
        }

        $domain->delete();

        return back()->with('success', 'Domain removed.');
    }

    // ── Plans ─────────────────────────────────────────────────

    public function plans()
    {
        $plans = SubscriptionPlan::withTrashed()
            ->withCount(['subscriptions as active_count' => fn ($q) => $q->where('status', 'active')])
            ->latest('id')
            ->get();

        return view('central.plans.index', compact('plans'));
    }

    public function storePlan(Request $request)
    {
        $data = $request->validate([
            'name'                 => 'required|string|max:255',
            'price_monthly'        => 'required|integer|min:0',
            'price_yearly'         => 'required|integer|min:0',
            'max_products'         => 'required|integer|min:1',
            'max_orders_per_month' => 'required|integer|min:1',
            'max_branches'         => 'required|integer|min:1',
            'features_json'        => 'nullable|string',
            'is_active'            => 'boolean',
        ]);

        if (isset($data['features_json'])) {
            $decoded = json_decode($data['features_json'], true);
            $data['features_json'] = is_array($decoded) ? $decoded : null;
        }

        $data['is_active'] = $request->boolean('is_active', true);

        SubscriptionPlan::create($data);

        return redirect()->route('central.plans')
            ->with('success', 'Plan created successfully.');
    }

    public function updatePlan(Request $request, int $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);

        $data = $request->validate([
            'name'                 => 'required|string|max:255',
            'price_monthly'        => 'required|integer|min:0',
            'price_yearly'         => 'required|integer|min:0',
            'max_products'         => 'required|integer|min:1',
            'max_orders_per_month' => 'required|integer|min:1',
            'max_branches'         => 'required|integer|min:1',
            'features_json'        => 'nullable|string',
            'is_active'            => 'boolean',
        ]);

        if (isset($data['features_json'])) {
            $decoded = json_decode($data['features_json'], true);
            $data['features_json'] = is_array($decoded) ? $decoded : null;
        }

        $data['is_active'] = $request->boolean('is_active', true);

        $plan->update($data);

        return redirect()->route('central.plans')
            ->with('success', 'Plan updated successfully.');
    }

    public function destroyPlan(int $id)
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->delete();

        return redirect()->route('central.plans')
            ->with('success', 'Plan deleted.');
    }
}
