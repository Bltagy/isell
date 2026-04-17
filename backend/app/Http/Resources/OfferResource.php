<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OfferResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                   => $this->id,
            'code'                 => $this->code,
            'type'                 => $this->type,
            'value'                => $this->value,
            'min_order_amount'     => $this->min_order_amount,
            'min_order_amount_egp' => number_format($this->min_order_amount / 100, 2),
            'max_discount_amount'  => $this->max_discount_amount,
            'applicable_to'        => $this->applicable_to,
            'start_date'           => $this->start_date?->toDateString(),
            'end_date'             => $this->end_date?->toDateString(),
            'usage_limit'          => $this->usage_limit,
            'used_count'           => $this->used_count,
        ];
    }
}
