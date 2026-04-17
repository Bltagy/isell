<?php

namespace App\Services;

use App\Models\Order;
use App\Models\TenantSetting;

class KashierService
{
    private function getMerchantId(): string
    {
        return (string) TenantSetting::where('key', 'kashier_merchant_id')->value('value') ?? '';
    }

    private function getApiKey(): string
    {
        return (string) TenantSetting::where('key', 'kashier_api_key')->value('value') ?? '';
    }

    private function getMode(): string
    {
        return env('KASHIER_MODE', 'test');
    }

    private function getBaseUrl(): string
    {
        return env('KASHIER_BASE_URL', 'https://checkout.kashier.io');
    }

    /**
     * Generate HMAC-SHA256 hash for a Kashier order.
     * Hash message format: ?payment={merchantId}.{orderId}.{amount}.{currency}
     */
    public function generateHash(string $merchantId, string $orderId, string $amount, string $currency): string
    {
        $message = "?payment={$merchantId}.{$orderId}.{$amount}.{$currency}";
        return hash_hmac('sha256', $message, $this->getApiKey());
    }

    /**
     * Build full Kashier payment URL for an order.
     */
    public function buildPaymentUrl(Order $order): string
    {
        $merchantId = $this->getMerchantId();
        $amount     = number_format($order->total / 100, 2, '.', '');
        $currency   = 'EGP';
        $orderId    = (string) $order->id;
        $hash       = $this->generateHash($merchantId, $orderId, $amount, $currency);

        $params = http_build_query([
            'merchantId' => $merchantId,
            'orderId'    => $orderId,
            'amount'     => $amount,
            'currency'   => $currency,
            'hash'       => $hash,
            'successUrl' => url("/api/v1/payments/kashier-success?order_id={$orderId}"),
            'failureUrl' => url("/api/v1/payments/kashier-failure?order_id={$orderId}"),
            'webhookUrl' => url('/api/v1/payments/kashier-webhook'),
            'metaData'   => json_encode(['order_id' => $orderId]),
            'mode'       => $this->getMode(),
            'display'    => 'en',
        ]);

        return $this->getBaseUrl() . '?' . $params;
    }

    /**
     * Verify Kashier webhook HMAC-SHA256 signature.
     */
    public function verifyWebhookSignature(array $payload): bool
    {
        $receivedHash = $payload['signature'] ?? '';
        $orderId      = $payload['orderId'] ?? '';
        $amount       = $payload['orderAmount'] ?? '';
        $currency     = $payload['currency'] ?? 'EGP';
        $merchantId   = $this->getMerchantId();

        $expectedHash = $this->generateHash($merchantId, $orderId, $amount, $currency);

        return hash_equals($expectedHash, $receivedHash);
    }
}
