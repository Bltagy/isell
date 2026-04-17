<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Order extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'user_id', 'address_id', 'status', 'payment_status', 'payment_method',
        'kashier_order_id', 'subtotal', 'delivery_fee',
        'discount', 'tax', 'total',
        'notes', 'estimated_delivery_minutes', 'driver_id',
    ];

    protected $casts = [
        'subtotal'                   => 'integer',
        'delivery_fee'               => 'integer',
        'discount'                   => 'integer',
        'tax'                        => 'integer',
        'total'                      => 'integer',
        'estimated_delivery_minutes' => 'integer',
    ];

    // ─── Relationships ────────────────────────────────────────

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function address(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(UserAddress::class, 'address_id');
    }

    public function driver(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function items(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(OrderItem::class);
    }

    public function statusHistory(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(OrderStatusHistory::class);
    }

    public function reviews(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Review::class);
    }

    // ─── Scopes ───────────────────────────────────────────────

    public function scopePending($query)
    {
        return $query->where('status', 'pending');
    }

    public function scopeActive($query)
    {
        return $query->whereNotIn('status', ['delivered', 'cancelled', 'refunded']);
    }

    // ─── Money Accessors ─────────────────────────────────────

    public function getTotalEgpAttribute(): string
    {
        return number_format($this->total / 100, 2);
    }

    public function getTotalFormattedAttribute(): string
    {
        return number_format($this->total / 100, 2).' ج.م';
    }

    // ─── Helpers ─────────────────────────────────────────────

    public function isCancellable(): bool
    {
        return in_array($this->status, ['pending', 'confirmed']);
    }
}
