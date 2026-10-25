<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Casts\Attribute;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Coupon extends Model
{
    public const TYPES = [
        'percent' => 'Porcentaje',
        'fixed' => 'Monto fijo',
        'free_delivery' => 'Envío gratis',
    ];

    protected $fillable = [
        'code', 'description', 'type', 'value', 'max_discount', 'min_order', 'business_id',
        'first_order_only', 'max_uses', 'uses', 'expires_at', 'active',
    ];

    protected function casts(): array
    {
        return [
            'value' => 'float',
            'max_discount' => 'float',
            'min_order' => 'float',
            'first_order_only' => 'boolean',
            'active' => 'boolean',
            'expires_at' => 'datetime',
        ];
    }

    protected function code(): Attribute
    {
        return Attribute::set(fn (string $value) => strtoupper(trim($value)));
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public static function findByCode(?string $code): ?self
    {
        return $code ? static::where('code', strtoupper(trim($code)))->first() : null;
    }

    /** Motivo por el que no se puede usar, o null si es válido. */
    public function rejectionFor(User $user, Business $business, float $subtotal): ?string
    {
        return match (true) {
            ! $this->active => 'Este cupón ya no está activo.',
            $this->expires_at?->isPast() ?? false => 'Este cupón expiró.',
            $this->max_uses !== null && $this->uses >= $this->max_uses => 'Este cupón ya alcanzó su límite de usos.',
            $this->business_id !== null && $this->business_id !== $business->id => 'Este cupón no aplica para este negocio.',
            $subtotal < $this->min_order => 'Este cupón requiere un pedido mínimo de $'.number_format($this->min_order, 2).'.',
            $this->first_order_only && $user->orders()->where('status', '!=', 'cancelado')->exists() => 'Este cupón es solo para tu primer pedido.',
            default => null,
        };
    }

    /** Suma un uso solo si todavía quedan; devuelve false si se agotó justo ahora. */
    public function claimUse(): bool
    {
        return static::whereKey($this->id)
            ->where(fn ($q) => $q->whereNull('max_uses')->orWhereColumn('uses', '<', 'max_uses'))
            ->increment('uses') === 1;
    }

    public function discountFor(float $subtotal, float $deliveryFee): float
    {
        $discount = match ($this->type) {
            'percent' => $subtotal * $this->value / 100,
            'fixed' => $this->value,
            'free_delivery' => $deliveryFee,
            default => 0,
        };
        if ($this->max_discount !== null) {
            $discount = min($discount, $this->max_discount);
        }

        return round(min($discount, $subtotal + $deliveryFee), 2);
    }
}
