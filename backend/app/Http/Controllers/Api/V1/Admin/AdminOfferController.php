<?php

namespace App\Http\Controllers\Api\V1\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\OfferResource;
use App\Models\Offer;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AdminOfferController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $offers = Offer::withTrashed()->latest()->get()->map(function ($offer) {
            $totalDiscount = \App\Models\Order::where('discount', '>', 0)
                ->whereHas('items') // orders that used this offer (approximation via used_count)
                ->sum('discount');

            return array_merge($offer->toArray(), [
                'orders_count'   => $offer->used_count,
                'total_discount' => $offer->used_count * ($offer->value ?? 0),
            ]);
        });

        return $this->success($offers);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code'                 => 'required|string|unique:offers,code',
            'type'                 => 'required|in:percentage,fixed,free_delivery',
            'value'                => 'required|integer|min:0',
            'min_order_amount'     => 'integer|min:0',
            'max_discount_amount'  => 'nullable|integer',
            'start_date'           => 'nullable|date',
            'end_date'             => 'nullable|date|after:start_date',
            'usage_limit'          => 'nullable|integer|min:1',
            'applicable_to'        => 'in:all,categories,products',
            'is_active'            => 'boolean',
        ]);

        $offer = Offer::create(array_merge($data, ['code' => strtoupper($data['code'])]));

        return $this->success(new OfferResource($offer), 'Offer created', 201);
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $offer = Offer::findOrFail($id);

        $data = $request->validate([
            'type'                 => 'sometimes|in:percentage,fixed,free_delivery',
            'value'                => 'sometimes|integer|min:0',
            'min_order_amount'     => 'integer|min:0',
            'max_discount_amount'  => 'nullable|integer',
            'start_date'           => 'nullable|date',
            'end_date'             => 'nullable|date',
            'usage_limit'          => 'nullable|integer|min:1',
            'is_active'            => 'boolean',
        ]);

        $offer->update($data);

        return $this->success(new OfferResource($offer), 'Offer updated');
    }

    public function destroy(int $id): JsonResponse
    {
        Offer::findOrFail($id)->delete();
        return $this->success(null, 'Offer deleted');
    }
}
