<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class Offer extends Model
{
    use HasFactory, SoftDeletes;

    protected $fillable = [
        'code', 'type', 'value', 'min_order_amount',
        'max_discount_amount', 'start_date', 'end_date',
        'usage_limit', 'used_count', 'applicable_to', 'is_active',
    ];

    protected $casts = [
        'value'               => 'integer',
        'min_order_amount'    => 'integer',
        'max_discount_amount' => 'integer',
        'usage_limit'         => 'integer',
        'used_count'          => 'integer',
        'is_active'           => 'boolean',
        'start_date'          => 'date',
        'end_date'            => 'date',
    ];

    // ─── Relationships ────────────────────────────────────────

    public function items(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(OfferItem::class);
    }

    // ─── Scopes ───────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_active', true)
            ->where(function ($q) {
                $q->whereNull('start_date')->orWhere('start_date', '<=', now());
            })
            ->where(function ($q) {
                $q->whereNull('end_date')->orWhere('end_date', '>=', now());
            });
    }

    // ─── Helpers ─────────────────────────────────────────────

    public function isValid(): bool
    {
        if (!$this->is_active) return false;
        if ($this->start_date && $this->start_date->isFuture()) return false;
        if ($this->end_date && $this->end_date->isPast()) return false;
        if ($this->usage_limit && $this->used_count >= $this->usage_limit) return false;
        return true;
    }

    /**
     * Calculate discount amount in piastres.
     */
    public function calculateDiscount(int $subtotalPiastres): int
    {
        if ($subtotalPiastres < $this->min_order_amount) {
            return 0;
        }

        $discount = match ($this->type) {
            'percentage'    => (int) round($subtotalPiastres * ($this->value / 100)),
            'fixed'         => $this->value,
            'free_delivery' => 0, // handled separately
            default         => 0,
        };

        if ($this->max_discount_amount) {
            $discount = min($discount, $this->max_discount_amount);
        }

        return $discount;
    }
}
