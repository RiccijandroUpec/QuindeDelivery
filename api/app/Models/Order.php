<?php

namespace App\Models;

use App\Events\DriverMoved;
use App\Events\OrderChanged;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\URL;

class Order extends Model
{
    public const STATUSES = [
        'pendiente' => 'Pendiente',
        'aceptado' => 'Aceptado por el negocio',
        'preparando' => 'Preparando',
        'listo' => 'Listo para recoger',
        'en_camino' => 'En camino',
        'entregado' => 'Entregado',
        'cancelado' => 'Cancelado',
    ];

    /** Estados en los que un repartidor puede tomar el pedido. */
    public const AVAILABLE_FOR_DRIVER = ['aceptado', 'preparando', 'listo'];

    protected $fillable = [
        'user_id', 'business_id', 'driver_id', 'status', 'address', 'reference', 'lat', 'lng',
        'subtotal', 'delivery_fee', 'service_fee', 'coupon_code', 'discount', 'commission', 'driver_earning', 'total', 'payment_method', 'cash_amount', 'transfer_proof', 'notes', 'cancel_reason', 'rating', 'rating_comment',
        'driver_lat', 'driver_lng', 'driver_location_at', 'delivered_at',
    ];

    /** Minutos que un pedido puede esperar a que el negocio lo acepte. */
    public const PENDING_TIMEOUT = 10;

    protected $appends = ['transfer_proof_url'];

    protected $hidden = ['transfer_proof'];

    protected function casts(): array
    {
        return [
            'lat' => 'float',
            'lng' => 'float',
            'subtotal' => 'float',
            'delivery_fee' => 'float',
            'discount' => 'float',
            'service_fee' => 'float',
            'commission' => 'float',
            'driver_earning' => 'float',
            'total' => 'float',
            'cash_amount' => 'float',
            'driver_lat' => 'float',
            'driver_lng' => 'float',
            'driver_location_at' => 'datetime',
            'delivered_at' => 'datetime',
            'rating' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        // Avisos en tiempo real. Si el servidor de Reverb no está prendido, la app sigue funcionando con polling.
        static::saved(function (Order $order) {
            if ($order->wasRecentlyCreated || $order->wasChanged(['status', 'driver_id', 'transfer_proof'])) {
                rescue(fn () => OrderChanged::dispatch($order), report: false);
            }
            if ($order->wasChanged(['driver_lat', 'driver_lng']) && $order->driver_lat !== null) {
                rescue(fn () => DriverMoved::dispatch($order->id, $order->driver_lat, $order->driver_lng), report: false);
            }
        });
    }

    /** El comprobante es privado: se entrega con un enlace firmado que vence en 30 minutos. */
    public function getTransferProofUrlAttribute(): ?string
    {
        return $this->transfer_proof
            ? URL::temporarySignedRoute('orders.proof', now()->addMinutes(30), ['order' => $this->id])
            : null;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function business(): BelongsTo
    {
        return $this->belongsTo(Business::class);
    }

    public function driver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'driver_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(OrderItem::class);
    }
}
