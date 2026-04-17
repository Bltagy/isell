<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class CategoryResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lang = app()->getLocale();

        return [
            'id'         => $this->id,
            'name'       => $lang === 'ar' ? $this->name_ar : $this->name_en,
            'name_en'    => $this->name_en,
            'name_ar'    => $this->name_ar,
            'image'      => $this->image,
            'image_url'  => $this->image,
            'parent_id'  => $this->parent_id,
            'sort_order' => $this->sort_order,
            'is_active'  => $this->is_active,
            'children'   => $this->whenLoaded('children', fn() => CategoryResource::collection($this->children)),
            'products_count' => $this->when(isset($this->products_count), $this->products_count),
        ];
    }
}
