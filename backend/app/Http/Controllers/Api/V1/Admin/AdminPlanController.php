<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Models\SubscriptionPlan;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminPlanController extends Controller
{
    use ApiResponse;

    /**
     * GET /central/api/plans
     */
    public function index(): JsonResponse
    {
        $plans = SubscriptionPlan::withTrashed()->latest()->get();

        return $this->success($plans);
    }

    /**
     * POST /central/api/plans
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'                 => 'required|string|max:255',
            'price_monthly'        => 'required|integer|min:0',
            'price_yearly'         => 'required|integer|min:0',
            'max_products'         => 'required|integer|min:1',
            'max_orders_per_month' => 'required|integer|min:1',
            'max_branches'         => 'required|integer|min:1',
            'features_json'        => 'nullable|array',
            'is_active'            => 'boolean',
        ]);

        $plan = SubscriptionPlan::create($data);

        return $this->success($plan, 'Plan created.', 201);
    }

    /**
     * PUT /central/api/plans/{id}
     */
    public function update(Request $request, int $id): JsonResponse
    {
        $plan = SubscriptionPlan::findOrFail($id);

        $data = $request->validate([
            'name'                 => 'sometimes|string|max:255',
            'price_monthly'        => 'sometimes|integer|min:0',
            'price_yearly'         => 'sometimes|integer|min:0',
            'max_products'         => 'sometimes|integer|min:1',
            'max_orders_per_month' => 'sometimes|integer|min:1',
            'max_branches'         => 'sometimes|integer|min:1',
            'features_json'        => 'nullable|array',
            'is_active'            => 'boolean',
        ]);

        $plan->update($data);

        return $this->success($plan, 'Plan updated.');
    }

    /**
     * DELETE /central/api/plans/{id}
     */
    public function destroy(int $id): JsonResponse
    {
        $plan = SubscriptionPlan::findOrFail($id);
        $plan->delete();

        return $this->success(null, 'Plan deleted.');
    }
}
