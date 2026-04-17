<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use App\Services\TenantService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminTenantController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly TenantService $tenantService) {}

    /**
     * GET /central/api/tenants
     * List all tenants with their active subscription info.
     */
    public function index(): JsonResponse
    {
        $tenants = Tenant::withTrashed()
            ->with(['primaryDomain', 'activeSubscription.plan'])
            ->latest()
            ->paginate(20);

        return $this->paginated($tenants, $tenants->map(fn (Tenant $t) => [
            'id'           => $t->id,
            'name'         => $t->name,
            'email'        => $t->email,
            'status'       => $t->status,
            'domain'       => $t->primaryDomain?->domain,
            'subscription' => $t->activeSubscription ? [
                'plan'       => $t->activeSubscription->plan?->name,
                'status'     => $t->activeSubscription->status,
                'end_date'   => $t->activeSubscription->end_date?->toDateString(),
            ] : null,
            'created_at'   => $t->created_at?->toDateTimeString(),
            'deleted_at'   => $t->deleted_at?->toDateTimeString(),
        ]));
    }

    /**
     * POST /central/api/tenants
     * Provision a new tenant via TenantService.
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'  => 'required|string|max:255',
            'email' => 'required|email|unique:tenants,email',
            'slug'  => 'nullable|string|alpha_dash|max:63|unique:domains,domain',
        ]);

        $tenant = $this->tenantService->provision($data);

        return $this->success([
            'id'     => $tenant->id,
            'name'   => $tenant->name,
            'email'  => $tenant->email,
            'status' => $tenant->status,
            'domain' => $tenant->primaryDomain?->domain,
        ], 'Tenant provisioned successfully.', 201);
    }

    /**
     * PATCH /central/api/tenants/{id}/suspend
     * Suspend a tenant.
     */
    public function suspend(string $id): JsonResponse
    {
        $tenant = Tenant::findOrFail($id);
        $tenant->update(['status' => 'suspended']);

        return $this->success(null, 'Tenant suspended.');
    }

    /**
     * DELETE /central/api/tenants/{id}
     * Soft-delete a tenant.
     */
    public function destroy(string $id): JsonResponse
    {
        $tenant = Tenant::findOrFail($id);
        $tenant->delete();

        return $this->success(null, 'Tenant deleted.');
    }
}
