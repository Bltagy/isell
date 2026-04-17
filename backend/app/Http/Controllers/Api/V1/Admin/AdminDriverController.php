<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Models\UserProfile;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminDriverController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $drivers = User::drivers()
            ->when($request->search, fn($q) => $q->where('name', 'like', "%{$request->search}%")
                ->orWhere('phone', 'like', "%{$request->search}%"))
            ->latest()
            ->paginate(20);

        return $this->paginated($drivers, UserResource::collection($drivers));
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'     => 'required|string',
            'email'    => 'nullable|email|unique:users,email',
            'phone'    => 'required|string|unique:users,phone',
            'password' => 'required|string|min:8',
        ]);

        $driver = User::create([
            'name'              => $data['name'],
            'email'             => $data['email'] ?? null,
            'phone'             => $data['phone'],
            'password'          => Hash::make($data['password']),
            'role'              => 'driver',
            'is_active'         => true,
            'phone_verified_at' => now(),
        ]);

        UserProfile::create(['user_id' => $driver->id]);
        $driver->assignRole('Driver');

        return $this->success(new UserResource($driver), 'Driver created', 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $driver = User::drivers()->findOrFail($id);

        $data = $request->validate([
            'name'      => 'sometimes|string',
            'phone'     => 'sometimes|string|unique:users,phone,'.$id,
            'is_active' => 'boolean',
        ]);

        $driver->update($data);

        return $this->success(new UserResource($driver), 'Driver updated');
    }

    public function destroy(int $id): JsonResponse
    {
        User::drivers()->findOrFail($id)->delete();
        return $this->success(null, 'Driver deleted');
    }
}
