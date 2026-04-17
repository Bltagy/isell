<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Resources\UserResource;
use App\Services\AuthService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Password;

class AuthController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly AuthService $authService) {}

    /**
     * POST /api/v1/auth/register
     */
    public function register(RegisterRequest $request): JsonResponse
    {
        $result = $this->authService->register($request->validated());

        return $this->success([
            'user'  => new UserResource($result['user']),
            'token' => $result['token'],
        ], 'Registration successful', 201);
    }

    /**
     * POST /api/v1/auth/login
     */
    public function login(LoginRequest $request): JsonResponse
    {
        $result = $this->authService->login($request->validated());

        return $this->success([
            'user'  => new UserResource($result['user']),
            'token' => $result['token'],
        ], 'Login successful');
    }

    /**
     * POST /api/v1/auth/send-otp
     */
    public function sendOtp(Request $request): JsonResponse
    {
        $request->validate(['phone' => 'required|string']);
        $this->authService->sendOtp($request->phone);

        return $this->success(null, 'OTP sent successfully');
    }

    /**
     * POST /api/v1/auth/verify-otp
     */
    public function verifyOtp(Request $request): JsonResponse
    {
        $request->validate([
            'phone' => 'required|string',
            'otp'   => 'required|string|size:6',
        ]);

        $result = $this->authService->verifyOtp($request->phone, $request->otp);

        return $this->success([
            'user'  => new UserResource($result['user']),
            'token' => $result['token'],
        ], 'OTP verified successfully');
    }

    /**
     * POST /api/v1/auth/logout
     */
    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return $this->success(null, 'Logged out successfully');
    }

    /**
     * POST /api/v1/auth/refresh-token
     */
    public function refreshToken(Request $request): JsonResponse
    {
        $user = $request->user();
        $user->tokens()->delete();
        $token = $user->createToken('auth_token')->plainTextToken;

        return $this->success(['token' => $token], 'Token refreshed');
    }

    /**
     * POST /api/v1/auth/forgot-password
     */
    public function forgotPassword(Request $request): JsonResponse
    {
        $request->validate(['email' => 'required|email']);
        Password::sendResetLink($request->only('email'));

        return $this->success(null, 'Password reset link sent if email exists');
    }

    /**
     * POST /api/v1/auth/reset-password
     */
    public function resetPassword(Request $request): JsonResponse
    {
        $request->validate([
            'token'                 => 'required',
            'email'                 => 'required|email',
            'password'              => 'required|min:8|confirmed',
        ]);

        $status = Password::reset(
            $request->only('email', 'password', 'password_confirmation', 'token'),
            function ($user, $password) {
                $user->forceFill(['password' => bcrypt($password)])->save();
                $user->tokens()->delete();
            }
        );

        if ($status === Password::PASSWORD_RESET) {
            return $this->success(null, 'Password reset successfully');
        }

        return $this->error('Invalid or expired reset token', 422);
    }
}
