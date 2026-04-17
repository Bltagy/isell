<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class OfferItem extends Model
{
    public $timestamps = false;

    protected $fillable = ['offer_id', 'item_type', 'item_id'];

    protected $casts = ['created_at' => 'datetime'];

    public function offer(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Offer::class);
    }
}
