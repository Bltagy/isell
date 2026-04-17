<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;

class AdminCustomerController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $customers = User::customers()
            ->with('profile')
            ->withCount('orders')
            ->withSum(['orders as total_spent' => fn($q) => $q->where('payment_status', 'paid')], 'total')
            ->when($request->search, fn($q) => $q->where(fn($q2) => $q2
                ->where('name', 'like', "%{$request->search}%")
                ->orWhere('phone', 'like', "%{$request->search}%")
                ->orWhere('email', 'like', "%{$request->search}%")))
            ->when($request->status, fn($q) => match ($request->status) {
                'active'   => $q->where('is_active', true),
                'inactive' => $q->where('is_active', false),
                default    => $q,
            })
            ->when($request->has_orders, fn($q) => $q->has('orders'))
            ->latest()
            ->paginate(20);

        return $this->paginated($customers, UserResource::collection($customers));
    }

    public function show(int $id): JsonResponse
    {
        $customer = User::customers()
            ->with(['profile', 'addresses', 'orders.items'])
            ->withCount('orders')
            ->withSum(['orders as total_spent' => fn($q) => $q->where('payment_status', 'paid')], 'total')
            ->findOrFail($id);

        return $this->success(new UserResource($customer));
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $customer = User::customers()->findOrFail($id);

        $validated = $request->validate([
            'name'     => 'sometimes|string|max:255',
            'email'    => 'sometimes|nullable|email|unique:users,email,' . $id,
            'phone'    => 'sometimes|nullable|string|max:20|unique:users,phone,' . $id,
            'password' => ['sometimes', 'nullable', Password::min(8)],
            'is_active'=> 'sometimes|boolean',
        ]);

        if (isset($validated['password']) && $validated['password']) {
            $validated['password'] = Hash::make($validated['password']);
        } else {
            unset($validated['password']);
        }

        $customer->update($validated);

        return $this->success(new UserResource($customer->fresh('profile')), 'Customer updated');
    }

    public function toggleStatus(int $id): JsonResponse
    {
        $customer = User::customers()->findOrFail($id);
        $customer->update(['is_active' => !$customer->is_active]);

        return $this->success(
            ['is_active' => $customer->is_active],
            $customer->is_active ? 'Customer activated' : 'Customer suspended'
        );
    }

    public function destroy(int $id): JsonResponse
    {
        $customer = User::customers()->findOrFail($id);
        $customer->delete();

        return $this->success(null, 'Customer deleted');
    }
}
