<?php

namespace App\Jobs;

use App\Jobs\Concerns\TenantAware;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

class SendOrderNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, TenantAware;

    private static array $messages = [
        'confirmed' => [
            'title_en' => 'Order Confirmed',
            'title_ar' => 'تم تأكيد طلبك',
            'body_en'  => 'Your order #%d has been confirmed.',
            'body_ar'  => 'تم تأكيد طلبك رقم #%d.',
        ],
        'preparing' => [
            'title_en' => 'Order Being Prepared',
            'title_ar' => 'جاري تحضير طلبك',
            'body_en'  => 'Your order #%d is being prepared.',
            'body_ar'  => 'جاري تحضير طلبك رقم #%d.',
        ],
        'out_for_delivery' => [
            'title_en' => 'Order Out for Delivery',
            'title_ar' => 'طلبك في الطريق إليك',
            'body_en'  => 'Your order #%d is on its way!',
            'body_ar'  => 'طلبك رقم #%d في الطريق إليك!',
        ],
        'delivered' => [
            'title_en' => 'Order Delivered',
            'title_ar' => 'تم توصيل طلبك',
            'body_en'  => 'Your order #%d has been delivered. Enjoy!',
            'body_ar'  => 'تم توصيل طلبك رقم #%d. بالهناء والشفاء!',
        ],
        'cancelled' => [
            'title_en' => 'Order Cancelled',
            'title_ar' => 'تم إلغاء طلبك',
            'body_en'  => 'Your order #%d has been cancelled.',
            'body_ar'  => 'تم إلغاء طلبك رقم #%d.',
        ],
    ];

    public function __construct(
        private readonly int $orderId,
        private readonly int $userId,
        private readonly string $event
    ) {
        $this->initializeTenantAware();
        $this->onQueue('notifications');
    }

    /**
     * Dispatch helper — accepts Order model but stores only primitives.
     */
    public static function dispatch(\App\Models\Order $order, string $event): static
    {
        $job = new static($order->id, $order->user_id, $event);
        dispatch($job);
        return $job;
    }

    public function handle(NotificationService $notificationService): void
    {
        $msg = self::$messages[$this->event] ?? null;
        if (!$msg) return;

        $orderId = $this->orderId;
        $userId  = $this->userId;

        $this->withTenantContext(function () use ($notificationService, $msg, $orderId, $userId) {
            $notificationService->sendToUser(
                $userId,
                $msg['title_en'],
                $msg['title_ar'],
                sprintf($msg['body_en'], $orderId),
                sprintf($msg['body_ar'], $orderId),
                'order',
                ['order_id' => $orderId, 'status' => $this->event]
            );
        });
    }
}
