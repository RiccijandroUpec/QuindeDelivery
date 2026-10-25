<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class Product extends Model
{
    protected $fillable = ['business_id', 'section', 'name', 'description', 'price', 'image', 'available'];

    protected $appends = ['image_url'];

    protected function casts(): array
    {
        return [
            'price' => 'float',
            'available' => 'boolean',
        ];
    }

    public function getImageUrlAttribute(): ?string
    {
        return $this->image ? Storage::disk('public')->url($this->image) : null;
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }
}
