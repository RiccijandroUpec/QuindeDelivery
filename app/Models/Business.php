<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;

class Business extends Model
{
    protected $fillable = [
        'category_id', 'name', 'description', 'logo', 'cover', 'address', 'phone', 'bank_info',
        'lat', 'lng', 'delivery_fee', 'min_order', 'time_min', 'time_max',
        'rating', 'rating_count', 'is_open', 'featured', 'active',
    ];

    protected $appends = ['logo_url', 'cover_url'];

    protected function casts(): array
    {
        return [
            'lat' => 'float',
            'lng' => 'float',
            'delivery_fee' => 'float',
            'min_order' => 'float',
            'rating' => 'float',
            'is_open' => 'boolean',
            'featured' => 'boolean',
            'active' => 'boolean',
        ];
    }

    public function getLogoUrlAttribute(): ?string
    {
        return $this->logo ? Storage::disk('public')->url($this->logo) : null;
    }

    public function getCoverUrlAttribute(): ?string
    {
        return $this->cover ? Storage::disk('public')->url($this->cover) : null;
    }

    public function category(): BelongsTo
    {
        return $this->belongsTo(Category::class);
    }

    public function products(): HasMany
    {
        return $this->hasMany(Product::class);
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    /** Recalcula la calificación con las reseñas de los clientes. */
    public function refreshRating(): void
    {
        $rated = $this->orders()->whereNotNull('rating');
        $this->update([
            'rating' => round((float) $rated->avg('rating'), 1),
            'rating_count' => $rated->count(),
        ]);
    }
}
