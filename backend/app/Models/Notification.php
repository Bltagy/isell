<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Factories\HasFactory;

class Notification extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id', 'title_en', 'title_ar', 'body_en', 'body_ar',
        'type', 'data_json', 'is_read', 'sent_via',
    ];

    protected $casts = [
        'data_json' => 'array',
        'is_read'   => 'boolean',
    ];

    public function user(): \Illuminate\Database\Eloquent\Relations\BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function scopeUnread($query)
    {
        return $query->where('is_read', false);
    }
}
