<?php

namespace App\Filament\Resources\Businesses\Schemas;

use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class BusinessForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->columns(3)
            ->components([
                Section::make('Información')
                    ->columnSpan(2)
                    ->columns(2)
                    ->schema([
                        TextInput::make('name')
                            ->label('Nombre')
                            ->required(),
                        Select::make('category_id')
                            ->label('Categoría')
                            ->relationship('category', 'name')
                            ->required()
                            ->preload(),
                        Textarea::make('description')
                            ->label('Descripción')
                            ->columnSpanFull(),
                        TextInput::make('address')
                            ->label('Dirección'),
                        TextInput::make('phone')
                            ->label('Teléfono')
                            ->tel(),
                        Textarea::make('bank_info')->label('Datos para transferencias')
                            ->placeholder('Banco, tipo y número de cuenta, titular')->rows(2)->columnSpanFull(),
                        TextInput::make('lat')
                            ->label('Latitud')
                            ->numeric(),
                        TextInput::make('lng')
                            ->label('Longitud')
                            ->numeric(),
                    ]),
                Section::make('Imágenes')
                    ->columnSpan(1)
                    ->schema([
                        FileUpload::make('logo')
                            ->image()
                            ->avatar()
                            ->disk('public')
                            ->directory('businesses'),
                        FileUpload::make('cover')
                            ->label('Portada')
                            ->image()
                            ->disk('public')
                            ->directory('businesses'),
                    ]),
                Section::make('Entrega')
                    ->columnSpan(2)
                    ->columns(3)
                    ->schema([
                        TextInput::make('delivery_fee')
                            ->label('Costo de envío')
                            ->numeric()
                            ->prefix('$')
                            ->default(1.5)
                            ->required(),
                        TextInput::make('min_order')
                            ->label('Pedido mínimo')
                            ->numeric()
                            ->prefix('$')
                            ->default(0),
                        TextInput::make('rating')
                            ->label('Calificación')
                            ->numeric()
                            ->minValue(0)
                            ->maxValue(5)
                            ->default(4.5),
                        TextInput::make('time_min')
                            ->label('Tiempo mín. (min)')
                            ->numeric()
                            ->default(20),
                        TextInput::make('time_max')
                            ->label('Tiempo máx. (min)')
                            ->numeric()
                            ->default(40),
                    ]),
                Section::make('Estado')
                    ->columnSpan(1)
                    ->schema([
                        Toggle::make('is_open')->label('Abierto ahora')->default(true),
                        Toggle::make('featured')->label('Destacado'),
                        Toggle::make('active')->label('Activo')->default(true),
                    ]),
            ]);
    }
}
