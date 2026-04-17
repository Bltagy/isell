<?php

namespace App\Events;

use App\Models\Notification;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class NewNotification implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public readonly Notification $notification) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel("notifications.{$this->notification->user_id}")];
    }

    public function broadcastAs(): string
    {
        return 'notification.new';
    }

    public function broadcastWith(): array
    {
        return [
            'id'      => $this->notification->id,
            'title'   => $this->notification->title_en,
            'body'    => $this->notification->body_en,
            'type'    => $this->notification->type,
            'is_read' => false,
        ];
    }
}
