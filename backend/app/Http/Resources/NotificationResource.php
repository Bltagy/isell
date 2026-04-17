<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class NotificationResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $lang = app()->getLocale();

        return [
            'id'         => $this->id,
            'title'      => $lang === 'ar' ? $this->title_ar : $this->title_en,
            'body'       => $lang === 'ar' ? $this->body_ar : $this->body_en,
            'type'       => $this->type,
            'data'       => $this->data_json,
            'is_read'    => $this->is_read,
            'sent_via'   => $this->sent_via,
            'created_at' => $this->created_at?->toISOString(),
        ];
    }
}
