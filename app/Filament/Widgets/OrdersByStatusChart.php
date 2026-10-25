<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class OrdersByStatusChart extends ChartWidget
{
    protected static ?int $sort = 2;

    protected ?string $heading = 'Pedidos de los últimos 7 días';

    protected ?string $maxHeight = '260px';

    private const COLORS = [
        'pendiente' => '#F2705E',
        'aceptado' => '#1F7A8C',
        'preparando' => '#6CC79A',
        'listo' => '#2E9E6B',
        'en_camino' => '#D9A441',
        'entregado' => '#1B5E3F',
        'cancelado' => '#B42318',
    ];

    protected function getData(): array
    {
        $counts = Order::where('created_at', '>=', today()->subDays(6))
            ->selectRaw('status, COUNT(*) as total')
            ->groupBy('status')
            ->pluck('total', 'status');

        $statuses = array_keys(array_filter(self::COLORS, fn ($_, $s) => $counts->has($s), ARRAY_FILTER_USE_BOTH));

        return [
            'datasets' => [[
                'data' => array_map(fn ($s) => $counts[$s], $statuses),
                'backgroundColor' => array_map(fn ($s) => self::COLORS[$s], $statuses),
            ]],
            'labels' => array_map(fn ($s) => Order::STATUSES[$s], $statuses),
        ];
    }

    protected function getType(): string
    {
        return 'doughnut';
    }
}
