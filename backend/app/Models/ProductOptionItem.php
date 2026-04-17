<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ProductOptionItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'option_id', 'name_en', 'name_ar', 'extra_price',
    ];

    protected $casts = [
        'extra_price' => 'integer',
    ];

    public function option(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(ProductOption::class, 'option_id');
    }

    public function getExtraPriceEgpAttribute(): string
    {
        return number_format($this->extra_price / 100, 2);
    }
}
