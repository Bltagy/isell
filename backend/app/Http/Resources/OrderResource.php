<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrderResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        // Resolve customer from the loaded user relationship or the order's user_id
        $user = $this->whenLoaded('user', fn() => $this->user);

        // Build a flat delivery address string from the nested address object
        $addressObj = $this->whenLoaded('address', fn() => $this->address);
        $deliveryAddress = null;
        if ($this->address) {
            $parts = array_filter([
                $this->address->address_line1,
                $this->address->address_line2,
                $this->address->district,
                $this->address->city,
            ]);
            $deliveryAddress = implode(', ', $parts);
        }

        return [
            'id'                         => $this->id,
            'order_number'               => (string) $this->id,
            'status'                     => $this->status,
            'payment_status'             => $this->payment_status,
            'payment_method'             => $this->payment_method,
            'kashier_order_id'           => $this->kashier_order_id,

            // Customer info — flat fields the dashboard modal needs
            'customer_name'              => $this->user?->name ?? 'Guest',
            'customer_phone'             => $this->user?->phone ?? '',
            'delivery_address'           => $deliveryAddress,

            'subtotal'                   => (int) $this->subtotal,
            'subtotal_egp'               => number_format($this->subtotal / 100, 2),
            'delivery_fee'               => (int) $this->delivery_fee,
            'delivery_fee_egp'           => number_format($this->delivery_fee / 100, 2),
            'discount'                   => (int) $this->discount,
            'discount_egp'               => number_format($this->discount / 100, 2),
            'tax'                        => (int) $this->tax,
            'tax_egp'                    => number_format($this->tax / 100, 2),
            'total'                      => (int) $this->total,
            'total_egp'                  => number_format($this->total / 100, 2),
            'total_formatted'            => number_format($this->total / 100, 2).' ج.م',
            'notes'                      => $this->notes,
            'estimated_delivery_minutes' => $this->estimated_delivery_minutes,
            'is_cancellable'             => $this->isCancellable(),

            // Nested objects
            'address'        => $addressObj,
            'driver'         => $this->whenLoaded('driver', fn() => $this->driver ? [
                'id'    => $this->driver->id,
                'name'  => $this->driver->name,
                'phone' => $this->driver->phone,
            ] : null),
            'driver_id'      => $this->driver?->id,
            'driver_name'    => $this->driver?->name,

            'items'          => $this->whenLoaded('items', fn() => OrderItemResource::collection($this->items)),
            'status_history' => $this->whenLoaded('statusHistory', fn() => $this->statusHistory->map(fn($h) => [
                'status'     => $h->status,
                'note'       => $h->note,
                'created_at' => $h->created_at?->toISOString(),
            ])),
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
