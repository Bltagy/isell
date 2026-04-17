<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotificationResource;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $notifications = $request->user()->notifications()->latest()->paginate(20);

        return $this->paginated($notifications, NotificationResource::collection($notifications));
    }

    public function markRead(Request $request, int $id): JsonResponse
    {
        $request->user()->notifications()->findOrFail($id)->update(['is_read' => true]);

        return $this->success(null, 'Notification marked as read');
    }

    public function markAllRead(Request $request): JsonResponse
    {
        $request->user()->notifications()->unread()->update(['is_read' => true]);

        return $this->success(null, 'All notifications marked as read');
    }

    public function unreadCount(Request $request): JsonResponse
    {
        $count = $request->user()->notifications()->unread()->count();

        return $this->success(['count' => $count]);
    }
}
