<?php

namespace App\Filament\Resources\Orders\Tables;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Actions\ViewAction;
use Filament\Notifications\Notification;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class OrdersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->poll('10s')
            ->columns([
                TextColumn::make('id')
                    ->label('#')
                    ->sortable(),
                TextColumn::make('created_at')
                    ->label('Fecha')
                    ->dateTime('d/m H:i')
                    ->sortable(),
                TextColumn::make('user.name')
                    ->label('Cliente')
                    ->searchable(),
                TextColumn::make('business.name')
                    ->label('Negocio')
                    ->searchable(),
                TextColumn::make('status')
                    ->label('Estado')
                    ->badge()
                    ->formatStateUsing(fn (string $state) => Order::STATUSES[$state] ?? $state)
                    ->color(fn (string $state) => OrderResource::statusColor($state)),
                TextColumn::make('driver.name')
                    ->label('Repartidor')
                    ->placeholder('Sin asignar'),
                TextColumn::make('total')
                    ->money('USD')
                    ->sortable(),
                TextColumn::make('payment_method')
                    ->label('Pago')
                    ->badge()
                    ->color('gray'),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->label('Estado')
                    ->options(Order::STATUSES),
                SelectFilter::make('business_id')
                    ->label('Negocio')
                    ->relationship('business', 'name'),
            ])
            ->recordActions([
                Action::make('advance')
                    ->label(fn (Order $record) => OrderResource::nextStatus($record->status)
                        ? 'Marcar: '.Order::STATUSES[OrderResource::nextStatus($record->status)]
                        : '')
                    ->icon(Heroicon::OutlinedArrowRight)
                    ->color('primary')
                    ->visible(fn (Order $record) => OrderResource::nextStatus($record->status) !== null)
                    ->action(function (Order $record) {
                        $record->update(['status' => OrderResource::nextStatus($record->status)]);
                        Notification::make()->title('Pedido #'.$record->id.' actualizado')->success()->send();
                    }),
                Action::make('cancel')
                    ->label('Cancelar')
                    ->icon(Heroicon::OutlinedXCircle)
                    ->color('danger')
                    ->requiresConfirmation()
                    ->visible(fn (Order $record) => ! in_array($record->status, ['entregado', 'cancelado', 'en_camino']))
                    ->action(fn (Order $record) => $record->update(['status' => 'cancelado'])),
                ViewAction::make(),
                EditAction::make(),
            ]);
    }
}
