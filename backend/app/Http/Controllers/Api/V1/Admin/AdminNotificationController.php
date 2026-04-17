<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Jobs\BroadcastNotification;
use App\Models\User;
use App\Services\NotificationService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminNotificationController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly NotificationService $notificationService) {}

    /**
     * POST /api/v1/admin/notifications/broadcast
     */
    public function broadcast(Request $request): JsonResponse
    {
        $data = $request->validate([
            'target'       => 'required|in:all,segment,user',
            'user_id'      => 'required_if:target,user|integer|exists:users,id',
            'title_en'     => 'required|string',
            'title_ar'     => 'required|string',
            'body_en'      => 'required|string',
            'body_ar'      => 'required|string',
            'scheduled_at' => 'nullable|date|after:now',
        ]);

        $job = new BroadcastNotification($data);

        if (!empty($data['scheduled_at'])) {
            $job->delay(now()->diffInSeconds($data['scheduled_at']));
        }

        dispatch($job)->onQueue('notifications');

        return $this->success(null, 'Notification queued for delivery');
    }
}
