<?php

namespace App\Filament\Settlements;

use App\Models\Business;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

/** Lo que cada negocio debe a la plataforma por comisiones. */
class BusinessSettlements extends TableWidget
{
    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Comisiones por negocio';

    public function table(Table $table): Table
    {
        return $table
            ->query(Business::query())
            ->filters([
                Period::filter(fn (Builder $q, $delivered) => $q
                    ->withCount(['orders as delivered_count' => $delivered])
                    ->withSum(['orders as sales' => $delivered], 'subtotal')
                    ->withSum(['orders as commission_total' => $delivered], 'commission')),
            ])
            ->defaultSort('name')
            ->columns([
                TextColumn::make('name')->label('Negocio')->weight('bold')->searchable(),
                TextColumn::make('delivered_count')->label('Pedidos entregados')->numeric(),
                TextColumn::make('sales')->label('Ventas')->money('USD')->placeholder('$0.00'),
                TextColumn::make('commission_rate')->label('Comisión actual')->suffix('%'),
                TextColumn::make('commission')->label('A cobrar al negocio')
                    ->state(fn (Business $record) => (float) ($record->commission_total ?? 0))
                    ->money('USD')
                    ->weight('bold')
                    ->color('primary'),
                TextColumn::make('net')->label('Neto para el negocio')
                    ->state(fn (Business $record) => round(($record->sales ?? 0) - ($record->commission_total ?? 0), 2))
                    ->money('USD'),
            ]);
    }
}
