<?php

namespace App\Filament\Widgets;

use App\Models\Order;
use Filament\Widgets\ChartWidget;

class SalesChart extends ChartWidget
{
    protected static ?int $sort = 1;

    protected ?string $heading = 'Ventas';

    protected ?string $description = 'Pedidos entregados por día';

    protected ?string $maxHeight = '260px';

    public ?string $filter = '7';

    protected function getFilters(): ?array
    {
        return ['7' => 'Últimos 7 días', '14' => 'Últimos 14 días', '30' => 'Últimos 30 días'];
    }

    protected function getData(): array
    {
        $days = (int) $this->filter;
        $from = today()->subDays($days - 1);

        $totals = Order::query()
            ->where('status', 'entregado')
            ->where('created_at', '>=', $from)
            ->selectRaw('DATE(created_at) as day, SUM(total) as total, COUNT(*) as orders')
            ->groupBy('day')
            ->get()
            ->keyBy('day');

        $labels = $sales = $orders = [];
        for ($d = $from->copy(); $d->lte(today()); $d->addDay()) {
            $row = $totals->get($d->toDateString());
            $labels[] = $d->translatedFormat('d M');
            $sales[] = round((float) ($row->total ?? 0), 2);
            $orders[] = (int) ($row->orders ?? 0);
        }

        return [
            'datasets' => [
                [
                    'label' => 'Ventas ($)',
                    'data' => $sales,
                    'borderColor' => '#1B5E3F',
                    'backgroundColor' => 'rgba(46, 158, 107, 0.15)',
                    'fill' => true,
                    'tension' => 0.35,
                ],
                [
                    'label' => 'Pedidos',
                    'data' => $orders,
                    'borderColor' => '#F2705E',
                    'backgroundColor' => 'transparent',
                    'tension' => 0.35,
                    'yAxisID' => 'y1',
                ],
            ],
            'labels' => $labels,
        ];
    }

    protected function getOptions(): array
    {
        return [
            'scales' => [
                'y' => ['beginAtZero' => true],
                'y1' => ['beginAtZero' => true, 'position' => 'right', 'grid' => ['drawOnChartArea' => false]],
            ],
        ];
    }

    protected function getType(): string
    {
        return 'line';
    }
}
