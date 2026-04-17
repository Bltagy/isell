<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Requests\Order\CreateOrderRequest;
use App\Http\Resources\OrderResource;
use App\Models\Order;
use App\Services\OrderService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrderController extends Controller
{
    use ApiResponse;

    public function __construct(private readonly OrderService $orderService) {}

    /**
     * POST /api/v1/orders
     */
    public function store(CreateOrderRequest $request): JsonResponse
    {
        $result = $this->orderService->createOrder($request->validated(), $request->user()->id);

        $data = ['order' => new OrderResource($result['order'])];

        if ($result['payment_url']) {
            $data['payment_url'] = $result['payment_url'];
        }

        return $this->success($data, 'Order placed successfully', 201);
    }

    /**
     * GET /api/v1/orders
     */
    public function index(Request $request): JsonResponse
    {
        $orders = Order::where('user_id', $request->user()->id)
            ->with(['items'])
            ->latest()
            ->paginate(20);

        return $this->paginated($orders, OrderResource::collection($orders));
    }

    /**
     * GET /api/v1/orders/{id}
     */
    public function show(Request $request, int $id): JsonResponse
    {
        $order = Order::where('user_id', $request->user()->id)
            ->with(['items', 'address', 'driver', 'statusHistory'])
            ->findOrFail($id);

        return $this->success(new OrderResource($order));
    }

    /**
     * POST /api/v1/orders/{id}/cancel
     */
    public function cancel(Request $request, int $id): JsonResponse
    {
        $order = Order::where('user_id', $request->user()->id)->findOrFail($id);

        if ($order->status !== 'pending') {
            return $this->error('Order can only be cancelled when status is pending.', 422);
        }

        $this->orderService->updateStatus($order, 'cancelled', $request->user()->id, 'Cancelled by customer');

        return $this->success(null, 'Order cancelled successfully');
    }

    /**
     * POST /api/v1/orders/{id}/reorder
     */
    public function reorder(Request $request, int $id): JsonResponse
    {
        $originalOrder = Order::where('user_id', $request->user()->id)
            ->with('items')
            ->findOrFail($id);

        // Re-build items from original order, checking current availability
        $items = $originalOrder->items->map(fn($item) => [
            'product_id' => $item->product_id,
            'quantity'   => $item->quantity,
        ])->toArray();

        $data = [
            'items'          => $items,
            'address_id'     => $originalOrder->address_id,
            'payment_method' => $originalOrder->payment_method,
            'notes'          => null,
        ];

        $result = $this->orderService->createOrder($data, $request->user()->id);

        $response = ['order' => new OrderResource($result['order'])];
        if ($result['payment_url']) {
            $response['payment_url'] = $result['payment_url'];
        }

        return $this->success($response, 'Reorder placed successfully', 201);
    }

    /**
     * GET /api/v1/orders/{id}/track
     */
    public function track(Request $request, int $id): JsonResponse
    {
        $order = Order::where('user_id', $request->user()->id)
            ->with(['statusHistory', 'driver'])
            ->findOrFail($id);

        return $this->success([
            'order_id'       => $order->id,
            'current_status' => $order->status,
            'history'        => $order->statusHistory->map(fn($h) => [
                'status'     => $h->status,
                'note'       => $h->note,
                'created_at' => $h->created_at?->toISOString(),
            ]),
            'driver' => $order->driver ? [
                'name'  => $order->driver->name,
                'phone' => $order->driver->phone,
            ] : null,
        ]);
    }
}
