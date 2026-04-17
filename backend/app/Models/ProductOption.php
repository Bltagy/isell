<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class ProductOption extends Model
{
    use HasFactory;

    protected $fillable = [
        'product_id', 'name_en', 'name_ar', 'type', 'is_required', 'max_selections',
    ];

    protected $casts = [
        'is_required'    => 'boolean',
        'max_selections' => 'integer',
    ];

    public function product(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function items(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(ProductOptionItem::class, 'option_id');
    }
}
