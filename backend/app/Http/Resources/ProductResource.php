<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class ProductResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lang = app()->getLocale();

        return [
            'id'                       => $this->id,
            'category_id'              => $this->category_id,
            'name'                     => $lang === 'ar' ? $this->name_ar : $this->name_en,
            'name_en'                  => $this->name_en,
            'name_ar'                  => $this->name_ar,
            'description'              => $lang === 'ar' ? $this->description_ar : $this->description_en,
            'description_en'           => $this->description_en,
            'description_ar'           => $this->description_ar,
            'image'                    => $this->image,
            'image_url'                => $this->image,
            'images'                   => $this->images_json ?? [],
            'price'                    => $this->price,
            'price_egp'                => $this->formatted_price_egp,
            'price_formatted'          => $this->formatted_price_egp.' ج.م',
            'discount_price'           => $this->discount_price,
            'discount_price_egp'       => $this->formatted_discount_price_egp,
            'effective_price'          => $this->effective_price,
            'is_available'             => $this->is_available,
            'is_featured'              => $this->is_featured,
            'preparation_time_minutes' => $this->preparation_time_minutes,
            'calories'                 => $this->calories,
            'category'                 => $this->whenLoaded('category', fn() => new CategoryResource($this->category)),
            'options'                  => $this->whenLoaded('options', fn() => ProductOptionResource::collection($this->options)),
            'average_rating'           => $this->whenLoaded('reviews', fn() => round($this->reviews->avg('rating'), 1)),
            'reviews_count'            => $this->whenLoaded('reviews', fn() => $this->reviews->count()),
            'is_favorited'             => $this->when(isset($this->is_favorited), $this->is_favorited),
        ];
    }
}
