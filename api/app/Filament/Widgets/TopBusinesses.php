<?php

namespace App\Filament\Widgets;

use App\Models\Business;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class TopBusinesses extends TableWidget
{
    protected static ?int $sort = 3;

    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Negocios que más venden (30 días)';

    public function table(Table $table): Table
    {
        $delivered = fn ($q) => $q->where('status', 'entregado')->where('created_at', '>=', today()->subDays(29));

        return $table
            ->query(
                Business::query()
                    ->withCount(['orders as delivered_count' => $delivered])
                    ->withSum(['orders as sales' => $delivered], 'subtotal')
                    ->orderByDesc('sales')
            )
            ->paginated([5, 10])
            ->defaultPaginationPageOption(5)
            ->columns([
                TextColumn::make('name')->label('Negocio')->weight('bold'),
                TextColumn::make('delivered_count')->label('Pedidos')->numeric(),
                TextColumn::make('sales')->label('Ventas')->money('USD')->placeholder('$0.00'),
                TextColumn::make('rating')->label('Calificación')
                    ->formatStateUsing(fn (Business $record) => '★ '.number_format($record->rating, 1)." ({$record->rating_count})"),
            ]);
    }
}
