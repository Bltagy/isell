<?php

namespace App\Events;

use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class OrderStatusUpdated implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(
        public readonly int $orderId,
        public readonly string $status
    ) {}

    public function broadcastOn(): array
    {
        // Broadcast to customer's private channel
        return [new PrivateChannel("order.{$this->orderId}")];
    }

    public function broadcastAs(): string
    {
        return 'status.updated';
    }

    public function broadcastWith(): array
    {
        return ['order_id' => $this->orderId, 'status' => $this->status];
    }
}
