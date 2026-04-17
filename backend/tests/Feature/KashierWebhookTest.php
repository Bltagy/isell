<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\TenantSetting;
use App\Models\User;
use App\Services\KashierService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class KashierWebhookTest extends TestCase
{
    use RefreshDatabase;

    private Order $order;
    private string $merchantId = 'test_merchant';
    private string $apiKey     = 'test_secret_key';

    protected function setUp(): void
    {
        parent::setUp();

        TenantSetting::insert([
            ['key' => 'kashier_merchant_id', 'value' => $this->merchantId, 'type' => 'string'],
            ['key' => 'kashier_api_key',     'value' => $this->apiKey,     'type' => 'string'],
        ]);

        $user = User::factory()->create(['role' => 'Customer']);

        $this->order = Order::create([
            'user_id'        => $user->id,
            'status'         => 'pending',
            'payment_status' => 'pending',
            'payment_method' => 'kashier',
            'subtotal'       => 10000,
            'delivery_fee'   => 2000,
            'discount'       => 0,
            'tax'            => 1400,
            'total'          => 13400,
        ]);
    }

    private function buildPayload(string $status, bool $validSignature = true): array
    {
        $orderId  = (string) $this->order->id;
        $amount   = number_format($this->order->total / 100, 2, '.', '');
        $currency = 'EGP';

        $message  = "?payment={$this->merchantId}.{$orderId}.{$amount}.{$currency}";
        $hash     = hash_hmac('sha256', $message, $this->apiKey);

        return [
            'orderId'       => $orderId,
            'orderAmount'   => $amount,
            'currency'      => $currency,
            'status'        => $status,
            'transactionId' => 'TXN_' . uniqid(),
            'signature'     => $validSignature ? $hash : 'invalid_signature',
        ];
    }

    public function test_valid_success_webhook_confirms_order(): void
    {
        $this->postJson('/api/v1/payments/kashier-webhook', $this->buildPayload('success'))
            ->assertOk();

        $this->order->refresh();
        $this->assertEquals('paid',      $this->order->payment_status);
        $this->assertEquals('confirmed', $this->order->status);
    }

    public function test_invalid_signature_returns_400_and_does_not_update_order(): void
    {
        $this->postJson('/api/v1/payments/kashier-webhook', $this->buildPayload('success', false))
            ->assertStatus(400);

        $this->order->refresh();
        $this->assertEquals('pending', $this->order->payment_status);
        $this->assertEquals('pending', $this->order->status);
    }

    public function test_failed_payment_webhook_sets_payment_status_to_failed(): void
    {
        $this->postJson('/api/v1/payments/kashier-webhook', $this->buildPayload('failure'))
            ->assertOk();

        $this->order->refresh();
        $this->assertEquals('failed',  $this->order->payment_status);
        $this->assertEquals('pending', $this->order->status);
    }
}
