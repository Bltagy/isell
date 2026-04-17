<?php

namespace App\Events;

use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderPlaced implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public int $orderId;
    public int $total;
    public int $userId;
    public string $tenantId;

    public function __construct(\App\Models\Order $order)
    {
        // Store primitives only — avoids tenant DB connection issues in queue workers
        $this->orderId  = $order->id;
        $this->total    = $order->total;
        $this->userId   = $order->user_id;
        $this->tenantId = tenant('id') ?? '';
    }

    public function broadcastOn(): array
    {
        // Broadcast to tenant admin presence channel
        return [new \Illuminate\Broadcasting\PresenceChannel("tenant.{$this->tenantId}.admin")];
    }

    public function broadcastAs(): string
    {
        return 'order.placed';
    }

    public function broadcastWith(): array
    {
        return [
            'order_id' => $this->orderId,
            'total'    => $this->total,
            'status'   => 'pending',
        ];
    }
}
