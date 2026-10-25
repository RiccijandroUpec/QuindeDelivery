<?php

namespace App\Filament\Resources\Orders\Schemas;

use App\Models\Order;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class OrderForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Gestión del pedido')
                    ->columns(2)
                    ->columnSpanFull()
                    ->schema([
                        Select::make('status')
                            ->label('Estado')
                            ->options(Order::STATUSES)
                            ->required()
                            ->native(false),
                        Select::make('driver_id')
                            ->label('Repartidor')
                            ->relationship('driver', 'name', fn ($query) => $query->where('role', 'repartidor')->where('active', true))
                            ->searchable()
                            ->preload()
                            ->placeholder('Sin asignar'),
                        Textarea::make('notes')
                            ->label('Notas del cliente')
                            ->columnSpanFull(),
                    ]),
            ]);
    }
}
