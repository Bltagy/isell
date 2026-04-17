<?php

namespace App\Jobs;

use App\Jobs\Concerns\TenantAware;
use App\Models\User;
use App\Services\NotificationService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;

class BroadcastNotification implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, TenantAware;

    public function __construct(private readonly array $data)
    {
        $this->initializeTenantAware();
        $this->onQueue('notifications');
    }

    public function handle(NotificationService $notificationService): void
    {
        $data = $this->data;

        $this->withTenantContext(function () use ($notificationService, $data) {
            if ($data['target'] === 'user') {
                $notificationService->sendToUser(
                    $data['user_id'],
                    $data['title_en'],
                    $data['title_ar'],
                    $data['body_en'],
                    $data['body_ar'],
                    'broadcast'
                );
            } elseif ($data['target'] === 'all') {
                $notificationService->broadcastToAll(
                    $data['title_en'],
                    $data['title_ar'],
                    $data['body_en'],
                    $data['body_ar'],
                    'broadcast'
                );
            }
        });
    }
}
