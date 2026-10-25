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
        'lat', 'lng', 'delivery_fee', 'commission_rate', 'min_order', 'time_min', 'time_max',
        'rating', 'rating_count', 'is_open', 'opens_at', 'closes_at', 'featured', 'active',
    ];

    /** Zona horaria de los horarios de atención. */
    public const TIMEZONE = 'America/Guayaquil';

    protected $appends = ['logo_url', 'cover_url', 'open_now'];

    protected function casts(): array
    {
        return [
            'lat' => 'float',
            'lng' => 'float',
            'delivery_fee' => 'float',
            'commission_rate' => 'float',
            'min_order' => 'float',
            'rating' => 'float',
            'is_open' => 'boolean',
            'featured' => 'boolean',
            'active' => 'boolean',
        ];
    }

    /** Abierto si el negocio no está en pausa y la hora actual cae dentro de su horario. */
    public function isOpenNow(): bool
    {
        if (! $this->active || ! $this->is_open) {
            return false;
        }
        if (! $this->opens_at || ! $this->closes_at) {
            return true;
        }
        $now = now(self::TIMEZONE)->format('H:i:s');
        $opens = substr($this->opens_at, 0, 8);
        $closes = substr($this->closes_at, 0, 8);

        // Horarios que pasan la medianoche, por ejemplo 18:00 a 02:00.
        return $opens <= $closes
            ? $now >= $opens && $now < $closes
            : $now >= $opens || $now < $closes;
    }

    public function getOpenNowAttribute(): bool
    {
        return $this->isOpenNow();
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
