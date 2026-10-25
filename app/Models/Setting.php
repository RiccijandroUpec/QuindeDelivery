<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Cache;

/** Configuración clave-valor de la plataforma (tarifas, reparto del envío). */
class Setting extends Model
{
    protected $primaryKey = 'key';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['key', 'value'];

    /** Valores por defecto si el admin todavía no configuró nada. */
    public const DEFAULTS = [
        'service_fee' => 0.25, // $ que paga el cliente por pedido
        'driver_share' => 80, // % del envío para el repartidor; el resto es de la plataforma
    ];

    public static function get(string $key): mixed
    {
        $all = Cache::rememberForever('settings', fn () => static::pluck('value', 'key')->all());

        return $all[$key] ?? self::DEFAULTS[$key] ?? null;
    }

    public static function float(string $key): float
    {
        return (float) static::get($key);
    }

    public static function put(array $values): void
    {
        foreach ($values as $key => $value) {
            static::updateOrCreate(['key' => $key], ['value' => $value]);
        }
        Cache::forget('settings');
    }

    /** Tarifas que la app necesita para calcular el total antes de pedir. */
    public static function publicValues(): array
    {
        return ['service_fee' => static::float('service_fee')];
    }
}
