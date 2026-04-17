<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class TenantSetting extends Model
{
    use HasFactory;

    protected $fillable = ['key', 'value', 'type'];

    public function scopeByKey($query, string $key)
    {
        return $query->where('key', $key);
    }

    public function getCastedValueAttribute(): mixed
    {
        return match ($this->type) {
            'boolean' => filter_var($this->value, FILTER_VALIDATE_BOOLEAN),
            'json'    => json_decode($this->value, true),
            default   => $this->value,
        };
    }
}
