<?php
/**
 * Quick smoke test — run inside container:
 * php tests/smoke_test.php
 */

$base = 'http://nginx';
$host = 'demo.localhost';

function req(string $method, string $path, array $data = [], string $token = ''): array
{
    global $base, $host;
    $ch = curl_init($base . $path);
    $headers = [
        'Host: ' . $host,
        'Accept: application/json',
        'Content-Type: application/json',
    ];
    if ($token) $headers[] = 'Authorization: Bearer ' . $token;
    curl_setopt_array($ch, [
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_HTTPHEADER     => $headers,
        CURLOPT_CUSTOMREQUEST  => $method,
        CURLOPT_TIMEOUT        => 10,
    ]);
    if ($data) curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($data));
    $body = curl_exec($ch);
    $code = curl_getinfo($ch, CURLINFO_HTTP_CODE);
    curl_close($ch);
    return ['code' => $code, 'body' => json_decode($body, true)];
}

function check(string $label, array $res, callable $assert): void
{
    try {
        $assert($res);
        echo "  ✓ {$label}\n";
    } catch (\Throwable $e) {
        echo "  ✗ {$label}: " . $e->getMessage() . " (HTTP {$res['code']})\n";
        if (isset($res['body']['message'])) echo "    → " . $res['body']['message'] . "\n";
    }
}

echo "\n=== Food App API Smoke Test ===\n\n";

// Auth
$login = req('POST', '/api/v1/auth/login', ['email' => 'admin@foodapp.com', 'password' => 'password']);
check('POST /auth/login (admin)', $login, fn($r) => assert($r['body']['success'] === true));
$adminToken = $login['body']['data']['token'] ?? '';

$custLogin = req('POST', '/api/v1/auth/login', ['email' => 'ahmed@example.com', 'password' => 'password']);
check('POST /auth/login (customer)', $custLogin, fn($r) => assert($r['body']['success'] === true));
$custToken = $custLogin['body']['data']['token'] ?? '';

$reg = req('POST', '/api/v1/auth/register', [
    'name' => 'Test User', 'email' => 'smoketest_' . time() . '@test.com',
    'phone' => '+2019' . rand(10000000, 99999999), 'password' => 'password123', 'password_confirmation' => 'password123',
]);
check('POST /auth/register', $reg, fn($r) => assert($r['code'] === 201));

$otp = req('POST', '/api/v1/auth/send-otp', ['phone' => '+201666666666']);
check('POST /auth/send-otp', $otp, fn($r) => assert($r['body']['success'] === true));

echo "\n--- Public Endpoints ---\n";

check('GET /settings/app-config', req('GET', '/api/v1/settings/app-config'),
    fn($r) => assert(isset($r['body']['data']['app_name_en'])));

check('GET /home', req('GET', '/api/v1/home'),
    fn($r) => assert(count($r['body']['data']['banners']) === 3));

check('GET /categories', req('GET', '/api/v1/categories'),
    fn($r) => assert($r['body']['meta']['total'] === 8));

check('GET /categories/1/products', req('GET', '/api/v1/categories/1/products'),
    fn($r) => assert($r['body']['meta']['total'] > 0));

check('GET /products', req('GET', '/api/v1/products'),
    fn($r) => assert($r['body']['meta']['total'] === 30));

check('GET /products?search=kofta', req('GET', '/api/v1/products?search=kofta'),
    fn($r) => assert($r['body']['success'] === true));

check('GET /products/1', req('GET', '/api/v1/products/1'),
    fn($r) => assert($r['body']['data']['name_en'] === 'Mixed Grill Platter'));

check('GET /products/1/reviews', req('GET', '/api/v1/products/1/reviews'),
    fn($r) => assert($r['body']['success'] === true));

check('POST /offers/validate (WELCOME20)', req('POST', '/api/v1/offers/validate', ['code' => 'WELCOME20', 'subtotal_piastres' => 10000]),
    fn($r) => assert($r['body']['data']['discount_piastres'] === 2000));

check('POST /offers/validate (FREEDEL)', req('POST', '/api/v1/offers/validate', ['code' => 'FREEDEL', 'subtotal_piastres' => 15000]),
    fn($r) => assert($r['body']['data']['free_delivery'] === true));

echo "\n--- Authenticated Customer Endpoints ---\n";

check('GET /profile', req('GET', '/api/v1/profile', [], $custToken),
    fn($r) => assert($r['body']['data']['role'] === 'customer'));

check('GET /addresses', req('GET', '/api/v1/addresses', [], $custToken),
    fn($r) => assert($r['body']['success'] === true));

$addrRes = req('POST', '/api/v1/addresses', [
    'label' => 'home', 'address_line1' => '10 Tahrir St', 'city' => 'Cairo',
    'latitude' => 30.044, 'longitude' => 31.235, 'is_default' => false,
], $custToken);
check('POST /addresses', $addrRes, fn($r) => assert($r['code'] === 201));
$addrId = $addrRes['body']['data']['id'] ?? 1;

check('GET /orders', req('GET', '/api/v1/orders', [], $custToken),
    fn($r) => assert($r['body']['meta']['total'] > 0));

$orderRes = req('POST', '/api/v1/orders', [
    'items' => [['product_id' => 6, 'quantity' => 2]],
    'address_id' => $addrId,
    'payment_method' => 'cash',
    'notes' => 'Smoke test order',
], $custToken);
check('POST /orders (cash)', $orderRes, fn($r) => assert($r['code'] === 201 && $r['body']['data']['order']['status'] === 'pending'));
$orderId = $orderRes['body']['data']['order']['id'] ?? 1;

$kashierOrder = req('POST', '/api/v1/orders', [
    'items' => [['product_id' => 7, 'quantity' => 1]],
    'payment_method' => 'kashier',
], $custToken);
check('POST /orders (kashier) → payment_url', $kashierOrder,
    fn($r) => assert($r['code'] === 201 && isset($r['body']['data']['payment_url'])));

check('GET /orders/{id}', req('GET', "/api/v1/orders/{$orderId}", [], $custToken),
    fn($r) => assert($r['body']['data']['id'] === $orderId));

check('GET /orders/{id}/track', req('GET', "/api/v1/orders/{$orderId}/track", [], $custToken),
    fn($r) => assert(isset($r['body']['data']['current_status'])));

check('POST /orders/{id}/cancel', req('POST', "/api/v1/orders/{$orderId}/cancel", [], $custToken),
    fn($r) => assert($r['body']['success'] === true));

check('GET /notifications', req('GET', '/api/v1/notifications', [], $custToken),
    fn($r) => assert($r['body']['success'] === true));

check('GET /notifications/unread-count', req('GET', '/api/v1/notifications/unread-count', [], $custToken),
    fn($r) => assert(isset($r['body']['data']['count'])));

check('GET /favorites', req('GET', '/api/v1/favorites', [], $custToken),
    fn($r) => assert($r['body']['success'] === true));

check('POST /favorites/1/toggle', req('POST', '/api/v1/favorites/1/toggle', [], $custToken),
    fn($r) => assert(isset($r['body']['data']['is_favorited'])));

echo "\n--- Admin Endpoints ---\n";

check('GET /admin/dashboard/stats', req('GET', '/api/v1/admin/dashboard/stats', [], $adminToken),
    fn($r) => assert($r['body']['data']['total_customers'] >= 5));

check('GET /admin/orders', req('GET', '/api/v1/admin/orders', [], $adminToken),
    fn($r) => assert($r['body']['meta']['total'] > 0));

check('GET /admin/orders/1', req('GET', '/api/v1/admin/orders/1', [], $adminToken),
    fn($r) => assert($r['body']['data']['id'] === 1));

check('PUT /admin/orders/1/status → confirmed', req('PUT', '/api/v1/admin/orders/1/status', ['status' => 'confirmed'], $adminToken),
    fn($r) => assert($r['body']['success'] === true));

check('GET /admin/categories', req('GET', '/api/v1/admin/categories', [], $adminToken),
    fn($r) => assert(count($r['body']['data']) === 8));

check('GET /admin/products', req('GET', '/api/v1/admin/products', [], $adminToken),
    fn($r) => assert($r['body']['meta']['total'] === 30));

check('GET /admin/customers', req('GET', '/api/v1/admin/customers', [], $adminToken),
    fn($r) => assert($r['body']['meta']['total'] >= 5));

check('GET /admin/drivers', req('GET', '/api/v1/admin/drivers', [], $adminToken),
    fn($r) => assert($r['body']['success'] === true));

check('GET /admin/offers', req('GET', '/api/v1/admin/offers', [], $adminToken),
    fn($r) => assert(count($r['body']['data']) === 3));

check('GET /admin/banners', req('GET', '/api/v1/admin/banners', [], $adminToken),
    fn($r) => assert(count($r['body']['data']) === 3));

check('GET /admin/settings', req('GET', '/api/v1/admin/settings', [], $adminToken),
    fn($r) => assert(count($r['body']['data']) === 33));

check('PUT /admin/settings', req('PUT', '/api/v1/admin/settings', ['settings' => ['app_name_en' => 'My Restaurant']], $adminToken),
    fn($r) => assert($r['body']['success'] === true));

// Reset setting
req('PUT', '/api/v1/admin/settings', ['settings' => ['app_name_en' => 'Food App']], $adminToken);

echo "\n=== Done ===\n\n";
