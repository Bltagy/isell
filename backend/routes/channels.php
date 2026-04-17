<?php

use Illuminate\Support\Facades\Broadcast;

// Private channel: customer tracks their order by order ID
Broadcast::channel('order.{orderId}', function ($user, $orderId) {
    return $user->orders()->where('id', $orderId)->exists();
});

// Private channel: user notifications
Broadcast::channel('notifications.{userId}', function ($user, $userId) {
    return (int) $user->id === (int) $userId;
});

// Presence channel: tenant admin listens for new orders
Broadcast::channel('tenant.{tenantId}.admin', function ($user) {
    if ($user->isAdmin() || $user->role === 'branch_manager') {
        return ['id' => $user->id, 'name' => $user->name];
    }
    return false;
});
