<?php

namespace App\Listeners;

use App\Events\OrderPlaced;
use App\Jobs\Concerns\TenantAware;
use App\Services\NotificationService;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Queue\InteractsWithQueue;

class HandleOrderPlaced implements ShouldQueue
{
    use InteractsWithQueue, TenantAware;

    public function __construct()
    {
        $this->initializeTenantAware();
    }

    public function handle(OrderPlaced $event): void
    {
        $orderId = $event->orderId;
        $total   = $event->totalPiastres;

        $this->withTenantContext(function () use ($orderId, $total) {
            $notificationService = app(NotificationService::class);
            $admins = \App\Models\User::admins()->get();

            foreach ($admins as $admin) {
                $notificationService->sendToUser(
                    $admin->id,
                    'New Order Received',
                    'طلب جديد',
                    "New order #{$orderId} received — ".number_format($total / 100, 2).' EGP',
                    "طلب جديد رقم #{$orderId} — ".number_format($total / 100, 2).' ج.م',
                    'new_order',
                    ['order_id' => $orderId],
                    'in_app'
                );
            }
        });
    }
}
