<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;

class SubscriptionPlan extends Model
{
    use HasFactory, SoftDeletes;

    public $timestamps = false;

    protected $fillable = [
        'name',
        'price_monthly',
        'price_yearly',
        'max_products',
        'max_orders_per_month',
        'max_branches',
        'features_json',
        'is_active',
    ];

    protected $casts = [
        'features_json'        => 'array',
        'is_active'            => 'boolean',
        'price_monthly'        => 'integer',
        'price_yearly'         => 'integer',
        'max_products'         => 'integer',
        'max_orders_per_month' => 'integer',
        'max_branches'         => 'integer',
    ];

    // ─── Relationships ────────────────────────────────────────

    public function subscriptions(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(TenantSubscription::class, 'plan_id');
    }

    // ─── Scopes ───────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_active', true);
    }
}
