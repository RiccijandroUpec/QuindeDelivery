<?php

namespace App\Filament\Resources\Coupons;

use App\Filament\Resources\Coupons\Pages\ManageCoupons;
use App\Models\Coupon;
use BackedEnum;
use Filament\Actions\DeleteAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DateTimePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Table;
use UnitEnum;

class CouponResource extends Resource
{
    protected static ?string $model = Coupon::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedTicket;

    protected static string|UnitEnum|null $navigationGroup = 'Ventas';

    protected static ?string $modelLabel = 'cupón';

    protected static ?string $pluralModelLabel = 'cupones';

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            TextInput::make('code')->label('Código')->required()->unique(ignoreRecord: true)->maxLength(40)
                ->helperText('Ej: PRIMERA20. Se guarda en mayúsculas.'),
            TextInput::make('description')->label('Descripción')->maxLength(255),
            Select::make('type')->label('Tipo')->options(Coupon::TYPES)->required()->default('percent')->live(),
            TextInput::make('value')->label(fn ($get) => $get('type') === 'percent' ? 'Porcentaje' : 'Monto')
                ->numeric()->minValue(0)->default(0)
                ->suffix(fn ($get) => $get('type') === 'percent' ? '%' : '$')
                ->hidden(fn ($get) => $get('type') === 'free_delivery'),
            TextInput::make('max_discount')->label('Descuento máximo')->numeric()->prefix('$')
                ->visible(fn ($get) => $get('type') === 'percent'),
            TextInput::make('min_order')->label('Pedido mínimo')->numeric()->prefix('$')->default(0),
            Select::make('business_id')->label('Solo para el negocio')->relationship('business', 'name')
                ->searchable()->preload()->placeholder('Todos los negocios'),
            TextInput::make('max_uses')->label('Usos máximos')->numeric()->minValue(1)->placeholder('Sin límite'),
            DateTimePicker::make('expires_at')->label('Vence')->seconds(false),
            Toggle::make('first_order_only')->label('Solo primer pedido'),
            Toggle::make('active')->label('Activo')->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('code')->label('Código')->searchable()->weight('bold')->copyable(),
                TextColumn::make('type')->label('Tipo')->badge()->formatStateUsing(fn ($state) => Coupon::TYPES[$state] ?? $state),
                TextColumn::make('value')->label('Valor')
                    ->formatStateUsing(fn (Coupon $record) => match ($record->type) {
                        'percent' => rtrim(rtrim(number_format($record->value, 2), '0'), '.').'%',
                        'fixed' => '$'.number_format($record->value, 2),
                        default => 'Envío',
                    }),
                TextColumn::make('business.name')->label('Negocio')->placeholder('Todos'),
                TextColumn::make('uses')->label('Usos')
                    ->formatStateUsing(fn (Coupon $record) => $record->uses.($record->max_uses ? " / {$record->max_uses}" : '')),
                TextColumn::make('expires_at')->label('Vence')->dateTime('d/m/Y H:i')->placeholder('Nunca'),
                ToggleColumn::make('active')->label('Activo'),
            ])
            ->recordActions([
                EditAction::make(),
                DeleteAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ManageCoupons::route('/'),
        ];
    }
}
