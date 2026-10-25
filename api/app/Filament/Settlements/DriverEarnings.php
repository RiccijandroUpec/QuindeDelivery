<?php

namespace App\Filament\Settlements;

use App\Models\User;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;
use Illuminate\Database\Eloquent\Builder;

/** Ganancias de cada repartidor y el efectivo que cobró a los clientes. */
class DriverEarnings extends TableWidget
{
    protected int|string|array $columnSpan = 'full';

    protected static ?string $heading = 'Ganancias por repartidor';

    public function table(Table $table): Table
    {
        return $table
            ->query(User::query()->where('role', 'repartidor'))
            ->filters([
                Period::filter(fn (Builder $q, $delivered) => $q
                    ->withCount(['deliveries as delivered_count' => $delivered])
                    ->withSum(['deliveries as earnings' => $delivered], 'driver_earning')
                    ->withSum(['deliveries as cash' => fn ($q) => $delivered($q)->where('payment_method', 'efectivo')], 'total')),
            ])
            ->defaultSort('name')
            ->columns([
                TextColumn::make('name')->label('Repartidor')->weight('bold')->searchable(),
                TextColumn::make('vehicle')->label('Vehículo')->placeholder('-'),
                TextColumn::make('delivered_count')->label('Entregas')->numeric(),
                TextColumn::make('earnings')->label('Ganancia')->money('USD')->placeholder('$0.00')->weight('bold')->color('primary'),
                TextColumn::make('cash')->label('Efectivo cobrado')->money('USD')->placeholder('$0.00')
                    ->tooltip('Dinero en efectivo que el repartidor recibió de los clientes.'),
                TextColumn::make('to_hand_over')->label('Debe entregar')
                    ->state(fn (User $record) => round(($record->cash ?? 0) - ($record->earnings ?? 0), 2))
                    ->money('USD')
                    ->color(fn ($state) => $state > 0 ? 'warning' : 'success')
                    ->tooltip('Efectivo cobrado menos su ganancia. Si es negativo, la plataforma le debe.'),
            ]);
    }
}
