<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Filament\Resources\Orders\OrderResource;
use App\Models\Order;
use Filament\Infolists\Components\ImageEntry;
use Filament\Infolists\Components\RepeatableEntry;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OrderInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->columns(3)
            ->components([
                Section::make('Pedido')
                    ->columnSpan(2)
                    ->columns(2)
                    ->schema([
                        TextEntry::make('status')
                            ->label('Estado')
                            ->badge()
                            ->formatStateUsing(fn (string $state) => Order::STATUSES[$state] ?? $state)
                            ->color(fn (string $state) => OrderResource::statusColor($state)),
                        TextEntry::make('created_at')->label('Fecha')->dateTime('d/m/Y H:i'),
                        TextEntry::make('business.name')->label('Negocio'),
                        TextEntry::make('driver.name')->label('Repartidor')->placeholder('Sin asignar'),
                        TextEntry::make('cancel_reason')->label('Motivo de cancelación')
                            ->visible(fn (Order $record) => $record->status === 'cancelado')
                            ->placeholder('-')->columnSpanFull(),
                        TextEntry::make('notes')->label('Notas')->placeholder('-')->columnSpanFull(),
                        RepeatableEntry::make('items')
                            ->label('Productos')
                            ->columnSpanFull()
                            ->columns(4)
                            ->schema([
                                TextEntry::make('quantity')->label('Cant.'),
                                TextEntry::make('name')->label('Producto'),
                                TextEntry::make('price')->label('Precio')->money('USD'),
                                TextEntry::make('subtotal')->money('USD'),
                            ]),
                    ]),
                Section::make('Cliente y pago')
                    ->columnSpan(1)
                    ->schema([
                        TextEntry::make('user.name')->label('Cliente'),
                        TextEntry::make('user.phone')->label('Teléfono')->placeholder('-'),
                        TextEntry::make('address')->label('Dirección'),
                        TextEntry::make('reference')->label('Referencia')->placeholder('-'),
                        TextEntry::make('payment_method')->label('Método de pago')->badge(),
                        TextEntry::make('cash_amount')->label('Paga con')->money('USD')->placeholder('-'),
                        TextEntry::make('subtotal')->money('USD'),
                        TextEntry::make('delivery_fee')->label('Envío')->money('USD'),
                        TextEntry::make('total')->money('USD')->weight('bold'),
                        ImageEntry::make('transfer_proof')->label('Comprobante')->disk('public')
                            ->visible(fn (Order $record) => $record->transfer_proof !== null),
                        TextEntry::make('rating')->label('Calificación')
                            ->formatStateUsing(fn ($state) => str_repeat('★', $state).str_repeat('☆', 5 - $state))
                            ->helperText(fn (Order $record) => $record->rating_comment)
                            ->visible(fn (Order $record) => $record->rating !== null),
                    ]),
            ]);
    }
}
