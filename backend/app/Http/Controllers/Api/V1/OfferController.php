<?php

namespace App\Http\Controllers\Api\V1;

use App\Http\Controllers\Controller;
use App\Http\Resources\OfferResource;
use App\Models\Offer;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OfferController extends Controller
{
    use ApiResponse;

    /**
     * GET /api/v1/offers — public list of active offers
     */
    public function index(): JsonResponse
    {
        $offers = Offer::active()->orderBy('created_at', 'desc')->get();
        return $this->success(OfferResource::collection($offers));
    }

    /**
     * POST /api/v1/offers/validate-code
     */
    public function validateCode(Request $request): JsonResponse
    {
        $request->validate([
            'code'     => 'required|string',
            'subtotal' => 'required|integer|min:0',
        ]);

        $offer = Offer::active()->where('code', strtoupper($request->code))->first();

        if (!$offer || !$offer->isValid()) {
            return $this->error('Invalid or expired offer code.', 422);
        }

        if ($request->subtotal < $offer->min_order_amount) {
            return $this->error(
                'Minimum order amount of '.number_format($offer->min_order_amount / 100, 2).' EGP required.',
                422
            );
        }

        $discount = $offer->type === 'free_delivery'
            ? 0
            : $offer->calculateDiscount($request->subtotal);

        return $this->success([
            'offer' => [
                'code'          => $offer->code,
                'type'          => $offer->type,
                'value'         => $offer->value,
                'applicable_to' => $offer->applicable_to,
            ],
            'discount'      => $discount,
            'discount_egp'  => number_format($discount / 100, 2),
            'free_delivery' => $offer->type === 'free_delivery',
        ]);
    }
}
