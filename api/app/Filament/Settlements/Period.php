<?php

namespace App\Filament\Settlements;

use Carbon\CarbonImmutable;
use Filament\Tables\Filters\SelectFilter;
use Illuminate\Database\Eloquent\Builder;

/** Filtro de período compartido por las tablas de liquidaciones. */
class Period
{
    public const OPTIONS = [
        'this_week' => 'Esta semana',
        'last_week' => 'Semana pasada',
        'this_month' => 'Este mes',
        'last_month' => 'Mes pasado',
    ];

    /** @return array{0: CarbonImmutable, 1: CarbonImmutable} */
    public static function range(?string $period): array
    {
        $now = CarbonImmutable::now();

        return match ($period) {
            'last_week' => [$now->subWeek()->startOfWeek(), $now->subWeek()->endOfWeek()],
            'this_month' => [$now->startOfMonth(), $now->endOfMonth()],
            'last_month' => [$now->subMonthNoOverflow()->startOfMonth(), $now->subMonthNoOverflow()->endOfMonth()],
            default => [$now->startOfWeek(), $now->endOfWeek()],
        };
    }

    /**
     * Filtro que agrega las sumas de pedidos entregados en el período elegido.
     *
     * @param  callable(Builder, callable): Builder  $aggregate
     */
    public static function filter(callable $aggregate): SelectFilter
    {
        return SelectFilter::make('period')
            ->label('Período')
            ->options(self::OPTIONS)
            ->default('this_week')
            ->selectablePlaceholder(false)
            ->query(function (Builder $query, array $data) use ($aggregate) {
                [$from, $to] = self::range($data['value'] ?? null);

                return $aggregate($query, fn ($q) => $q->where('status', 'entregado')->whereBetween('delivered_at', [$from, $to]));
            });
    }
}
