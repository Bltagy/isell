<?php

namespace App\Jobs;

use App\Jobs\Concerns\TenantAware;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

class SendReviewReminder implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, TenantAware;

    public function __construct(
        private readonly int $orderId,
        private readonly int $userId
    ) {
        $this->initializeTenantAware();
        $this->onQueue('notifications');
    }

    public static function dispatch(\App\Models\Order $order): static
    {
        $job = new static($order->id, $order->user_id);
        dispatch($job);
        return $job;
    }

    public function handle(NotificationService $notificationService): void
    {
        $orderId = $this->orderId;
        $userId  = $this->userId;

        $this->withTenantContext(function () use ($notificationService, $orderId, $userId) {
            $notificationService->sendToUser(
                $userId,
                'How was your order?',
                'كيف كان طلبك؟',
                "Rate your order #{$orderId} and help us improve.",
                "قيّم طلبك رقم #{$orderId} وساعدنا على التحسين.",
                'review_reminder',
                ['order_id' => $orderId]
            );
        });
    }
}
