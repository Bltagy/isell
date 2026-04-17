<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductOptionResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lang = app()->getLocale();

        return [
            'id'             => $this->id,
            'name'           => $lang === 'ar' ? $this->name_ar : $this->name_en,
            'name_en'        => $this->name_en,
            'name_ar'        => $this->name_ar,
            'type'           => $this->type,
            'is_required'    => $this->is_required,
            'max_selections' => $this->max_selections,
            'items'          => $this->whenLoaded('items', fn() => $this->items->map(fn($item) => [
                'id'                    => $item->id,
                'name'                  => $lang === 'ar' ? $item->name_ar : $item->name_en,
                'name_en'               => $item->name_en,
                'name_ar'               => $item->name_ar,
                'extra_price'           => $item->extra_price,
                'extra_price_egp'       => number_format($item->extra_price / 100, 2),
            ])),
        ];
    }
}
