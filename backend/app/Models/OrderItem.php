<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class OrderItem extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id', 'product_id', 'product_name_snapshot',
        'quantity', 'unit_price', 'options_snapshot', 'subtotal',
    ];

    protected $casts = [
        'options_snapshot' => 'array',
        'quantity'         => 'integer',
        'unit_price'       => 'integer',
        'subtotal'         => 'integer',
    ];

    public function order(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Order::class);
    }

    public function product(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Product::class);
    }
}
