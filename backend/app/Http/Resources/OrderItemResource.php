<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderItemResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'              => $this->id,
            'product_id'      => $this->product_id,
            'name'            => $this->product_name_snapshot,
            'product_name'    => $this->product_name_snapshot, // alias for dashboard modal
            'quantity'        => $this->quantity,
            'unit_price'      => (int) $this->unit_price,
            'unit_price_egp'  => number_format($this->unit_price / 100, 2),
            'options'         => $this->options_snapshot ?? [],
            'subtotal'        => (int) $this->subtotal,
            'total_price'     => (int) $this->subtotal, // alias for dashboard modal
            'subtotal_egp'    => number_format($this->subtotal / 100, 2),
        ];
    }
}
