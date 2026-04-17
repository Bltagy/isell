<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Services\OrderService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminOrderController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly OrderService $orderService) {}

    public function index(Request $request): JsonResponse
    {
        $orders = Order::with(['user', 'items'])
            ->when($request->status, fn($q) => $q->where('status', $request->status))
            ->when($request->payment_status, fn($q) => $q->where('payment_status', $request->payment_status))
            ->when($request->search, fn($q) => $q->where('id', $request->search)
                ->orWhereHas('user', fn($u) => $u->where('name', 'like', "%{$request->search}%")
                    ->orWhere('phone', 'like', "%{$request->search}%")))
            ->when($request->date_from, fn($q) => $q->whereDate('created_at', '>=', $request->date_from))
            ->when($request->date_to, fn($q) => $q->whereDate('created_at', '<=', $request->date_to))
            ->latest()
            ->paginate(20);

        return $this->paginated($orders, OrderResource::collection($orders));
    }

    public function show(int $id): JsonResponse
    {
        $order = Order::with(['user', 'items', 'address', 'driver', 'statusHistory'])->findOrFail($id);

        return $this->success(new OrderResource($order));
    }

    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $request->validate([
            'status' => 'required|in:confirmed,preparing,ready,out_for_delivery,delivered,cancelled,refunded',
            'note'   => 'nullable|string',
        ]);

        $order = Order::findOrFail($id);
        $order = $this->orderService->updateStatus($order, $request->status, $request->user()->id, $request->note);

        return $this->success(new OrderResource($order), 'Order status updated');
    }

    public function assignDriver(Request $request, int $id): JsonResponse
    {
        $request->validate(['driver_id' => 'required|integer|exists:users,id']);

        $order = Order::findOrFail($id);
        $order->update(['driver_id' => $request->driver_id]);

        return $this->success(new OrderResource($order->fresh(['driver'])), 'Driver assigned');
    }
}
