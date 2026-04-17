<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BannerResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lang = app()->getLocale();

        return [
            'id'         => $this->id,
            'image'      => $this->image,
            'image_url'  => $this->image,
            'title'      => $lang === 'ar' ? $this->title_ar : $this->title_en,
            'link_type'  => $this->link_type,
            'link_value' => $this->link_value,
            'sort_order' => $this->sort_order,
        ];
    }
}
