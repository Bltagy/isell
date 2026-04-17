<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\ReviewResource;
use App\Models\Order;
use App\Models\Review;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ReviewController extends Controller
{
    use ApiResponse;

    /**
     * POST /api/v1/reviews
     */
    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'order_id'   => 'required|integer|exists:orders,id',
            'product_id' => 'required|integer|exists:products,id',
            'rating'     => 'required|integer|min:1|max:5',
            'comment'    => 'nullable|string|max:1000',
        ]);

        // Ensure order belongs to user and is delivered
        $order = Order::where('user_id', $request->user()->id)
            ->where('status', 'delivered')
            ->findOrFail($data['order_id']);

        // Ensure product was in the order
        $inOrder = $order->items()->where('product_id', $data['product_id'])->exists();
        if (!$inOrder) {
            return $this->error('Product was not part of this order.', 422);
        }

        // Prevent duplicate review
        $exists = Review::where('user_id', $request->user()->id)
            ->where('order_id', $data['order_id'])
            ->where('product_id', $data['product_id'])
            ->exists();

        if ($exists) {
            return $this->error('You have already reviewed this product for this order.', 422);
        }

        $review = Review::create(array_merge($data, ['user_id' => $request->user()->id]));

        return $this->success(new ReviewResource($review->load('user')), 'Review submitted', 201);
    }
}
