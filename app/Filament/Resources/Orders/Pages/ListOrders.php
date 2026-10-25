<?php

namespace App\Filament\Resources\Orders\Pages;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;

class ListOrders extends ListRecords
{
    protected static string $resource = OrderResource::class;

    public function getTabs(): array
    {
        return [
            'activos' => Tab::make('Activos')
                ->badge(Order::whereNotIn('status', ['entregado', 'cancelado'])->count())
                ->modifyQueryUsing(fn ($query) => $query->whereNotIn('status', ['entregado', 'cancelado'])),
            'entregados' => Tab::make('Entregados')
                ->modifyQueryUsing(fn ($query) => $query->where('status', 'entregado')),
            'cancelados' => Tab::make('Cancelados')
                ->modifyQueryUsing(fn ($query) => $query->where('status', 'cancelado')),
            'todos' => Tab::make('Todos'),
        ];
    }
}
