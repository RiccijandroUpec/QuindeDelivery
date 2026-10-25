<?php

namespace App\Filament\Widgets;

use App\Filament\Settlements\PlatformRevenue;
use App\Models\Business;
use App\Models\Order;
use App\Models\User;
use Filament\Widgets\StatsOverviewWidget;
use Filament\Widgets\StatsOverviewWidget\Stat;

class DeliveryStats extends StatsOverviewWidget
{
    protected static ?int $sort = 0;

    protected ?string $pollingInterval = '15s';

    protected function getStats(): array
    {
        $today = Order::whereDate('created_at', today());

        return [
            Stat::make('Pedidos hoy', (clone $today)->count())
                ->description((clone $today)->where('status', 'entregado')->count().' entregados')
                ->color('primary'),
            Stat::make('Ventas hoy', '$'.number_format((clone $today)->where('status', 'entregado')->sum('total'), 2))
                ->color('success'),
            Stat::make('Ganancia Quinde hoy', '$'.number_format(PlatformRevenue::totals((clone $today)->where('status', 'entregado'))['net'], 2))
                ->description('Comisiones, servicio y envíos')
                ->color('success'),
            Stat::make('Pendientes', Order::where('status', 'pendiente')->count())
                ->description('Esperando aceptación')
                ->color('warning'),
            Stat::make('En camino', Order::where('status', 'en_camino')->count())
                ->description(User::where('role', 'repartidor')->where('active', true)->count().' repartidores activos'),
            Stat::make('Negocios abiertos', Business::where('active', true)->get()->filter->isOpenNow()->count()),
            Stat::make('Entrega promedio', $this->averageDeliveryMinutes().' min')
                ->description('Desde el pedido hasta la puerta (7 días)')
                ->color('info'),
        ];
    }

    private function averageDeliveryMinutes(): int
    {
        $minutes = Order::where('status', 'entregado')
            ->whereNotNull('delivered_at')
            ->where('created_at', '>=', today()->subDays(6))
            ->get(['created_at', 'delivered_at'])
            ->map(fn (Order $o) => $o->created_at->diffInMinutes($o->delivered_at));

        return (int) round($minutes->avg() ?? 0);
    }
}
