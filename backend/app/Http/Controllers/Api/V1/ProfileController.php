<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class ProfileController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/profile
     */
    public function show(Request $request): JsonResponse
    {
        return $this->success(new UserResource($request->user()->load('profile')));
    }

    /**
     * PUT /api/v1/profile
     */
    public function update(Request $request): JsonResponse
    {
        $data = $request->validate([
            'name'               => 'sometimes|string|max:255',
            'email'              => 'sometimes|email|unique:users,email,'.$request->user()->id,
            'phone'              => 'sometimes|nullable|string|unique:users,phone,'.$request->user()->id,
            'fcm_token'          => 'sometimes|nullable|string',
            'preferred_language' => 'sometimes|in:en,ar',
            'avatar'             => 'sometimes|image|max:2048',
        ]);

        if ($request->hasFile('avatar')) {
            $path = $request->file('avatar')->store('avatars', 's3');
            $data['avatar'] = Storage::disk('s3')->url($path);
        }

        $request->user()->update($data);

        return $this->success(new UserResource($request->user()->fresh('profile')), 'Profile updated');
    }

    /**
     * PUT /api/v1/profile/update-fcm-token
     */
    public function updateFcmToken(Request $request): JsonResponse
    {
        $request->validate(['fcm_token' => 'required|string']);
        $request->user()->update(['fcm_token' => $request->fcm_token]);

        return $this->success(null, 'FCM token updated');
    }
}
