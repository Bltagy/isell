<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Jobs\SendOrderNotification;
use App\Models\Order;
use App\Services\KashierService;
use App\Services\OrderService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

class PaymentController extends Controller
{
    use ApiResponse;

    public function __construct(
        private readonly KashierService $kashierService,
        private readonly OrderService $orderService,
    ) {}

    /**
     * POST /api/v1/payments/initiate
     */
    public function initiate(Request $request): JsonResponse
    {
        $request->validate(['order_id' => 'required|integer']);

        $order = Order::where('user_id', $request->user()->id)
            ->where('payment_method', 'kashier')
            ->where('payment_status', 'pending')
            ->findOrFail($request->order_id);

        $paymentUrl = $this->kashierService->buildPaymentUrl($order);

        return $this->success([
            'payment_url' => $paymentUrl,
            'order_id'    => $order->id,
        ]);
    }

    /**
     * POST /api/v1/payments/kashier-webhook
     */
    public function kashierWebhook(Request $request): JsonResponse
    {
        $payload = $request->all();

        Log::info('Kashier webhook received', $payload);

        if (!$this->kashierService->verifyWebhookSignature($payload)) {
            Log::warning('Kashier webhook signature mismatch', $payload);
            return response()->json(['status' => 'invalid_signature'], 400);
        }

        $order = Order::find($payload['orderId'] ?? null);

        if (!$order) {
            return response()->json(['status' => 'order_not_found'], 404);
        }

        $status = strtolower($payload['status'] ?? '');

        if ($status === 'success') {
            $order->update([
                'payment_status'   => 'paid',
                'kashier_order_id' => $payload['transactionId'] ?? null,
            ]);

            // Confirm the order and notify
            $this->orderService->updateStatus($order, 'confirmed');

            SendOrderNotification::dispatch($order, 'confirmed')->onQueue('notifications');
        } elseif ($status === 'failure') {
            $order->update(['payment_status' => 'failed']);
        }

        return response()->json(['status' => 'ok']);
    }
}
