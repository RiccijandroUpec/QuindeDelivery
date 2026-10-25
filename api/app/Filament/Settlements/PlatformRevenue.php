<?php

namespace App\Filament\Settlements;

use App\Models\Order;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

/** Ganancia de la plataforma: comisiones + tarifa de servicio + parte del envío − descuentos. */
class PlatformRevenue extends StatsOverviewWidget
{
    protected ?string $heading = 'Ganancia de Quinde';

    protected function getStats(): array
    {
        $stats = [];
        foreach (['this_week' => 'Esta semana', 'this_month' => 'Este mes'] as $period => $label) {
            [$from, $to] = Period::range($period);
            $r = self::totals(Order::where('status', 'entregado')->whereBetween('delivered_at', [$from, $to]));
            $stats[] = Stat::make($label, '$'.number_format($r['net'], 2))
                ->description(sprintf(
                    'Comisiones $%s · Servicio $%s · Envíos $%s · Cupones −$%s',
                    number_format($r['commission'], 2), number_format($r['service'], 2),
                    number_format($r['delivery'], 2), number_format($r['discount'], 2),
                ))
                ->color($r['net'] >= 0 ? 'success' : 'danger');
        }

        return $stats;
    }

    /** @return array{commission: float, service: float, delivery: float, discount: float, net: float} */
    public static function totals($query): array
    {
        $row = $query->selectRaw('COALESCE(SUM(commission),0) as commission, COALESCE(SUM(service_fee),0) as service,
            COALESCE(SUM(delivery_fee - driver_earning),0) as delivery, COALESCE(SUM(discount),0) as discount')->first();

        $r = [
            'commission' => (float) $row->commission,
            'service' => (float) $row->service,
            'delivery' => (float) $row->delivery,
            'discount' => (float) $row->discount,
        ];
        // Los cupones los paga la plataforma (marketing).
        $r['net'] = round($r['commission'] + $r['service'] + $r['delivery'] - $r['discount'], 2);

        return $r;
    }
}
