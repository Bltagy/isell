<?php

namespace Tests\Feature;

use App\Models\Otp;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class OtpLoginTest extends TestCase
{
    use RefreshDatabase;

    public function test_sending_otp_creates_record_with_10_minute_expiry(): void
    {
        $user = User::factory()->create(['phone' => '+201001234567', 'role' => 'Customer']);

        $this->postJson('/api/v1/auth/send-otp', ['phone' => '+201001234567'])
            ->assertOk();

        $otp = Otp::where('user_id', $user->id)->latest()->first();
        $this->assertNotNull($otp);
        $this->assertNull($otp->used_at);
        $this->assertTrue($otp->expires_at->isFuture());
        $this->assertTrue($otp->expires_at->diffInMinutes(now()) <= 10);
    }

    public function test_verifying_valid_otp_returns_token(): void
    {
        $user = User::factory()->create(['phone' => '+201001234567', 'role' => 'Customer']);
        Otp::create([
            'user_id'    => $user->id,
            'code'       => '123456',
            'expires_at' => now()->addMinutes(10),
        ]);

        $response = $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '+201001234567',
            'otp'   => '123456',
        ]);

        $response->assertOk()
            ->assertJsonPath('data.token', fn($v) => !empty($v));

        $this->assertNotNull(Otp::where('user_id', $user->id)->whereNotNull('used_at')->first());
    }

    public function test_verifying_expired_otp_returns_422(): void
    {
        $user = User::factory()->create(['phone' => '+201001234567', 'role' => 'Customer']);
        Otp::create([
            'user_id'    => $user->id,
            'code'       => '999999',
            'expires_at' => now()->subMinutes(1),
        ]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '+201001234567',
            'otp'   => '999999',
        ])->assertStatus(422);
    }

    public function test_verifying_wrong_otp_returns_422(): void
    {
        $user = User::factory()->create(['phone' => '+201001234567', 'role' => 'Customer']);
        Otp::create([
            'user_id'    => $user->id,
            'code'       => '111111',
            'expires_at' => now()->addMinutes(10),
        ]);

        $this->postJson('/api/v1/auth/verify-otp', [
            'phone' => '+201001234567',
            'otp'   => '000000',
        ])->assertStatus(422);
    }
}
