<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\SoftDeletes;
use Laravel\Scout\Searchable;

class Product extends Model
{
    use HasFactory, SoftDeletes, Searchable;

    protected $fillable = [
        'category_id', 'name_en', 'name_ar', 'description_en', 'description_ar',
        'price', 'discount_price', 'image', 'images_json',
        'is_available', 'preparation_time_minutes', 'calories',
        'is_featured', 'sort_order',
    ];

    protected $casts = [
        'images_json'               => 'array',
        'is_available'              => 'boolean',
        'is_featured'               => 'boolean',
        'price'            => 'integer',
        'discount_price'   => 'integer',
        'preparation_time_minutes'  => 'integer',
        'calories'                  => 'integer',
        'sort_order'                => 'integer',
    ];

    // ─── Relationships ────────────────────────────────────────

    public function category(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function options(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(ProductOption::class);
    }

    public function reviews(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(Review::class);
    }

    public function favoritedBy(): \Illuminate\Database\Eloquent\Relations\BelongsToMany
    {
        return $this->belongsToMany(User::class, 'favorites');
    }

    // ─── Scopes ───────────────────────────────────────────────

    public function scopeActive($query)
    {
        return $query->where('is_available', true);
    }

    public function scopeAvailable($query)
    {
        return $query->where('is_available', true);
    }

    public function scopeFeatured($query)
    {
        return $query->where('is_featured', true);
    }

    // ─── Money Accessors ─────────────────────────────────────

    public function getEffectivePriceAttribute(): int
    {
        return $this->discount_price ?? $this->price;
    }

    public function getFormattedPriceEgpAttribute(): string
    {
        return number_format($this->price / 100, 2);
    }

    public function getFormattedDiscountPriceEgpAttribute(): ?string
    {
        if (!$this->discount_price) {
            return null;
        }
        return number_format($this->discount_price / 100, 2);
    }

    public function getPriceEgpAttribute(): string
    {
        return number_format($this->price / 100, 2);
    }

    // ─── Scout ───────────────────────────────────────────────

    public function searchableAs(): string
    {
        // Tenant-scoped index: tenant_{tenantId}_products
        $tenantId = tenancy()->tenant?->id ?? 'default';
        return "tenant_{$tenantId}_products";
    }

    public function toSearchableArray(): array
    {
        return [
            'id'          => $this->id,
            'name_en'     => $this->name_en,
            'name_ar'     => $this->name_ar,
            'description_en' => $this->description_en,
            'description_ar' => $this->description_ar,
            'category_id' => $this->category_id,
            'is_available' => $this->is_available,
            'price' => $this->price,
        ];
    }
}
