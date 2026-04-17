<?php

namespace App\Models;

use Stancl\Tenancy\Database\Models\Tenant as BaseTenant;
use Stancl\Tenancy\Contracts\TenantWithDatabase;
use Stancl\Tenancy\Database\Concerns\HasDatabase;
use Stancl\Tenancy\Database\Concerns\HasDomains;
use Illuminate\Database\Eloquent\SoftDeletes;

class Tenant extends BaseTenant implements TenantWithDatabase
{
    use HasDatabase, HasDomains, SoftDeletes;

    protected $fillable = [
        'id',
        'name',
        'email',
        'status',
    ];

    protected $casts = [
        'status' => 'string',
    ];

    /**
     * Custom columns stored in the tenants table (not in data JSON).
     */
    public static function getCustomColumns(): array
    {
        return [
            'id',
            'name',
            'email',
            'status',
        ];
    }

    // ─── Relationships ────────────────────────────────────────

    public function domains(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Domain::class, 'tenant_id');
    }

    public function primaryDomain(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(Domain::class, 'tenant_id')->where('is_primary', true);
    }

    public function subscriptions(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(TenantSubscription::class);
    }

    public function activeSubscription(): \Illuminate\Database\Eloquent\Relations\HasOne
    {
        return $this->hasOne(TenantSubscription::class)
            ->where('status', 'active')
            ->latest();
    }

    // ─── Scopes ───────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('status', 'active');
    }

    public function scopeSuspended($query)
    {
        return $query->where('status', 'suspended');
    }
}
