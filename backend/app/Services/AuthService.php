<?php

namespace App\Services;

use App\Models\Otp;
use App\Models\User;
use App\Models\UserProfile;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
use Illuminate\Validation\ValidationException;

class AuthService
{
    /**
     * Register a new customer.
     */
    public function register(array $data): array
    {
        $user = User::create([
            'name'               => $data['name'],
            'email'              => $data['email'],
            'phone'              => $data['phone'] ?? null,
            'password'           => Hash::make($data['password']),
            'role'               => 'Customer',
            'is_active'          => true,
            'preferred_language' => $data['preferred_language'] ?? 'ar',
        ]);

        UserProfile::create(['user_id' => $user->id]);
        $user->assignRole('Customer');

        $token = $user->createToken('auth_token')->plainTextToken;

        return ['user' => $user->load('profile'), 'token' => $token];
    }

    /**
     * Login with phone + password (customers) or email + password (admins/drivers).
     * When otp_login_enabled setting is false, customers use phone + password.
     */
    public function login(array $data): array
    {
        // Look up by phone or email depending on what was provided
        if (!empty($data['phone'])) {
            $user = User::where('phone', $data['phone'])->first();
        } else {
            $user = User::where('email', $data['email'])->first();
        }

        if (!$user || !Hash::check($data['password'], $user->password)) {
            throw ValidationException::withMessages([
                'phone' => ['Invalid credentials.'],
            ]);
        }

        if (!$user->is_active) {
            throw ValidationException::withMessages([
                'phone' => ['Your account has been suspended.'],
            ]);
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return ['user' => $user->load('profile'), 'token' => $token];
    }

    /**
     * Generate and store OTP in the otps table, send via mail.
     */
    public function sendOtp(string $phone): string
    {
        $otp = str_pad((string) random_int(0, 999999), 6, '0', STR_PAD_LEFT);

        // Find or create user by phone
        $user = User::firstOrCreate(
            ['phone' => $phone],
            [
                'name'               => 'User',
                'role'               => 'Customer',
                'is_active'          => true,
                'preferred_language' => 'ar',
            ]
        );

        // Invalidate previous unused OTPs
        Otp::where('user_id', $user->id)->whereNull('used_at')->delete();

        // Store new OTP with 10-minute expiry
        Otp::create([
            'user_id'    => $user->id,
            'code'       => $otp,
            'expires_at' => now()->addMinutes(10),
        ]);

        // Send via mail (SMS gateway can be swapped in production)
        if ($user->email) {
            Mail::raw("Your OTP code is: {$otp}. Valid for 10 minutes.", function ($msg) use ($user) {
                $msg->to($user->email)->subject('Your OTP Code');
            });
        }

        // Always log for dev
        logger("OTP for {$phone}: {$otp}");

        return $otp;
    }

    /**
     * Verify OTP from the otps table and return/create user.
     */
    public function verifyOtp(string $phone, string $otp): array
    {
        $user = User::where('phone', $phone)->first();

        if (!$user) {
            throw ValidationException::withMessages([
                'phone' => ['Phone number not found.'],
            ]);
        }

        $otpRecord = Otp::where('user_id', $user->id)
            ->where('code', $otp)
            ->whereNull('used_at')
            ->where('expires_at', '>', now())
            ->latest()
            ->first();

        if (!$otpRecord) {
            throw ValidationException::withMessages([
                'otp' => ['Invalid or expired OTP.'],
            ]);
        }

        // Mark OTP as used
        $otpRecord->update(['used_at' => now()]);

        // Mark phone as verified
        $user->update(['phone_verified_at' => now()]);

        if (!$user->profile) {
            UserProfile::create(['user_id' => $user->id]);
        }

        if (!$user->hasRole('Customer')) {
            $user->assignRole('Customer');
        }

        $token = $user->createToken('auth_token')->plainTextToken;

        return ['user' => $user->load('profile'), 'token' => $token];
    }
}
