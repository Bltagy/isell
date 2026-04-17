<?php

namespace App\Services;

use App\Events\OrderPlaced;
use App\Models\Offer;
use App\Models\Order;
use App\Models\OrderItem;
use App\Models\OrderStatusHistory;
use App\Models\Product;
use App\Models\TenantSetting;
use App\Services\NotificationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\ValidationException;

class OrderService
{
    public function __construct(private readonly KashierService $kashierService) {}

    /**
     * Calculate order totals from items, offer, and tenant settings.
     *
     * @param  array  $items  [['product_id', 'quantity', 'options'?], ...]
     * @param  string|null  $offerCode
     * @return array{items: array, subtotal: int, delivery_fee: int, discount: int, tax: int, total: int, free_delivery: bool}
     */
    public function calculateTotals(array $items, ?string $offerCode = null): array
    {
        $pricedItems  = [];
        $subtotal     = 0;

        foreach ($items as $item) {
            $product = Product::available()->findOrFail($item['product_id']);
            $price   = $product->effective_price;
            $extraPrice = 0;
            $optionsSnapshot = [];

            if (!empty($item['options'])) {
                foreach ($item['options'] as $optionData) {
                    $option = $product->options()->findOrFail($optionData['option_id']);
                    $selectedItems = [];
                    foreach ($optionData['item_ids'] as $itemId) {
                        $optionItem  = $option->items()->findOrFail($itemId);
                        $extraPrice += $optionItem->extra_price;
                        $selectedItems[] = [
                            'id'          => $optionItem->id,
                            'name_en'     => $optionItem->name_en,
                            'name_ar'     => $optionItem->name_ar,
                            'extra_price' => $optionItem->extra_price,
                        ];
                    }
                    $optionsSnapshot[] = [
                        'option_id' => $option->id,
                        'name_en'   => $option->name_en,
                        'name_ar'   => $option->name_ar,
                        'items'     => $selectedItems,
                    ];
                }
            }

            $unitPrice = $price + $extraPrice;
            $itemTotal = $unitPrice * $item['quantity'];
            $subtotal += $itemTotal;

            $pricedItems[] = [
                'product_id'            => $product->id,
                'product_name_snapshot' => $product->name_en,
                'quantity'              => $item['quantity'],
                'unit_price'            => $unitPrice,
                'options_snapshot'      => $optionsSnapshot ?: null,
                'subtotal'              => $itemTotal,
            ];
        }

        // Apply offer
        $discount     = 0;
        $freeDelivery = false;

        if ($offerCode) {
            $offer = Offer::active()->where('code', $offerCode)->first();
            if ($offer && $offer->isValid() && $subtotal >= $offer->min_order_amount) {
                if ($offer->type === 'free_delivery') {
                    $freeDelivery = true;
                } else {
                    $discount = $offer->calculateDiscount($subtotal);
                }
            }
        }

        $deliveryFee = $freeDelivery ? 0 : (int) TenantSetting::where('key', 'delivery_fee_egp')->value('value');
        $taxRate     = (float) TenantSetting::where('key', 'tax_percentage')->value('value') / 100;
        $taxable     = $subtotal - $discount;
        $tax         = (int) round($taxable * $taxRate);
        $total       = $taxable + $deliveryFee + $tax;

        return compact('pricedItems', 'subtotal', 'deliveryFee', 'discount', 'tax', 'total', 'freeDelivery');
    }

    /**
     * Create a new order.
     */
    public function createOrder(array $data, int $userId): array
    {
        return DB::transaction(function () use ($data, $userId) {
            // 1. Validate and price items
            $items    = [];
            $subtotal = 0;

            foreach ($data['items'] as $item) {
                $product = Product::available()->findOrFail($item['product_id']);
                $price   = $product->effective_price;

                // Add option extras
                $optionsSnapshot = [];
                $extraPrice      = 0;

                if (!empty($item['options'])) {
                    foreach ($item['options'] as $optionData) {
                        $option = $product->options()->findOrFail($optionData['option_id']);
                        $selectedItems = [];

                        foreach ($optionData['item_ids'] as $itemId) {
                            $optionItem  = $option->items()->findOrFail($itemId);
                            $extraPrice += $optionItem->extra_price;
                            $selectedItems[] = [
                                'id'          => $optionItem->id,
                                'name_en'     => $optionItem->name_en,
                                'name_ar'     => $optionItem->name_ar,
                                'extra_price' => $optionItem->extra_price,
                            ];
                        }

                        $optionsSnapshot[] = [
                            'option_id'   => $option->id,
                            'name_en'     => $option->name_en,
                            'name_ar'     => $option->name_ar,
                            'items'       => $selectedItems,
                        ];
                    }
                }

                $unitPrice  = $price + $extraPrice;
                $itemTotal  = $unitPrice * $item['quantity'];
                $subtotal  += $itemTotal;

                $items[] = [
                    'product_id'           => $product->id,
                    'product_name_snapshot' => $product->name_en,
                    'quantity'             => $item['quantity'],
                    'unit_price'           => $unitPrice,
                    'options_snapshot'     => $optionsSnapshot ?: null,
                    'subtotal'             => $itemTotal,
                ];
            }

            // 2. Apply offer
            $discountPiastres = 0;
            $freeDelivery     = false;

            if (!empty($data['offer_code'])) {
                $offer = Offer::active()->where('code', $data['offer_code'])->first();

                if (!$offer || !$offer->isValid()) {
                    throw ValidationException::withMessages(['offer_code' => ['Invalid or expired offer code.']]);
                }

                if ($subtotal < $offer->min_order_amount) {
                    throw ValidationException::withMessages(['offer_code' => [
                        'Minimum order amount not met for this offer.',
                    ]]);
                }

                if ($offer->type === 'free_delivery') {
                    $freeDelivery = true;
                } else {
                    $discountPiastres = $offer->calculateDiscount($subtotal);
                }

                $offer->increment('used_count');
            }

            // 3. Calculate totals
            $deliveryFee = $freeDelivery ? 0 : (int) TenantSetting::where('key', 'delivery_fee_egp')->value('value');
            $taxRate     = (float) TenantSetting::where('key', 'tax_percentage')->value('value') / 100;
            $taxable     = $subtotal - $discountPiastres;
            $tax         = (int) round($taxable * $taxRate);
            $total       = $taxable + $deliveryFee + $tax;

            // Check minimum order amount
            $minOrderAmount = (int) TenantSetting::where('key', 'min_order_amount_egp')->value('value');
            if ($total < $minOrderAmount) {
                throw ValidationException::withMessages([
                    'total' => ['Order total is below the minimum order amount.'],
                ]);
            }

            // 4. Create order
            $order = Order::create([
                'user_id'        => $userId,
                'address_id'     => $data['address_id'] ?? null,
                'status'         => 'pending',
                'payment_status' => 'pending',
                'payment_method' => $data['payment_method'],
                'subtotal'       => $subtotal,
                'delivery_fee'   => $deliveryFee,
                'discount'       => $discountPiastres,
                'tax'            => $tax,
                'total'          => $total,
                'notes'          => $data['notes'] ?? null,
            ]);

            // 5. Create items
            foreach ($items as $item) {
                OrderItem::create(array_merge($item, ['order_id' => $order->id]));
            }

            // 6. Status history
            OrderStatusHistory::create([
                'order_id'   => $order->id,
                'status'     => 'pending',
                'changed_by' => $userId,
            ]);

            // 7. Fire event
            event(new OrderPlaced($order));

            // 8. Build payment URL if Kashier
            $paymentUrl = null;
            if ($data['payment_method'] === 'kashier') {
                $paymentUrl = $this->kashierService->buildPaymentUrl($order);
            }

            return ['order' => $order->load(['items', 'address']), 'payment_url' => $paymentUrl];
        });
    }

    /**
     * Update order status (admin).
     */
    public function updateStatus(Order $order, string $status, ?int $adminId = null, ?string $note = null): Order
    {
        $order->update(['status' => $status]);

        OrderStatusHistory::create([
            'order_id'   => $order->id,
            'status'     => $status,
            'note'       => $note,
            'changed_by' => $adminId,
        ]);

        // Broadcast status update via WebSocket (Reverb)
        event(new \App\Events\OrderStatusUpdated($order->id, $status));

        // Send notification — synchronously saves to DB, then queues FCM push.
        // Using app() so it works whether queue is sync or async.
        $this->sendStatusNotification($order, $status);

        // Dispatch review reminder 30 minutes after delivery
        if ($status === 'delivered') {
            \App\Jobs\SendReviewReminder::dispatch($order)
                ->onQueue('notifications');
        }

        return $order->fresh(['items', 'address', 'statusHistory']);
    }

    /**
     * Save the notification to DB immediately (no queue dependency),
     * then dispatch FCM push via queue.
     */
    private function sendStatusNotification(Order $order, string $status): void
    {
        $messages = [
            'confirmed'        => ['title_en' => 'Order Confirmed',        'title_ar' => 'تم تأكيد طلبك',         'body_en' => 'Your order #%d has been confirmed.',       'body_ar' => 'تم تأكيد طلبك رقم #%d.'],
            'preparing'        => ['title_en' => 'Order Being Prepared',   'title_ar' => 'جاري تحضير طلبك',       'body_en' => 'Your order #%d is being prepared.',        'body_ar' => 'جاري تحضير طلبك رقم #%d.'],
            'ready'            => ['title_en' => 'Order Ready',            'title_ar' => 'طلبك جاهز',              'body_en' => 'Your order #%d is ready for pickup.',      'body_ar' => 'طلبك رقم #%d جاهز للاستلام.'],
            'out_for_delivery' => ['title_en' => 'Order Out for Delivery', 'title_ar' => 'طلبك في الطريق إليك',   'body_en' => 'Your order #%d is on its way!',            'body_ar' => 'طلبك رقم #%d في الطريق إليك!'],
            'delivered'        => ['title_en' => 'Order Delivered',        'title_ar' => 'تم توصيل طلبك',         'body_en' => 'Your order #%d has been delivered. Enjoy!','body_ar' => 'تم توصيل طلبك رقم #%d. بالهناء والشفاء!'],
            'cancelled'        => ['title_en' => 'Order Cancelled',        'title_ar' => 'تم إلغاء طلبك',         'body_en' => 'Your order #%d has been cancelled.',       'body_ar' => 'تم إلغاء طلبك رقم #%d.'],
        ];

        $msg = $messages[$status] ?? null;
        if (!$msg) return;

        // Save to DB immediately — no queue needed
        app(NotificationService::class)->sendToUser(
            $order->user_id,
            $msg['title_en'],
            $msg['title_ar'],
            sprintf($msg['body_en'], $order->id),
            sprintf($msg['body_ar'], $order->id),
            'order',
            ['order_id' => $order->id, 'status' => $status],
            'both'
        );
    }
}
