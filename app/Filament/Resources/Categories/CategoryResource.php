<?php

namespace App\Filament\Resources\Categories;

use App\Filament\Resources\Categories\Pages\CreateCategory;
use App\Filament\Resources\Categories\Pages\EditCategory;
use App\Filament\Resources\Categories\Pages\ListCategories;
use App\Filament\Resources\Categories\Pages\ViewCategory;
use App\Models\Category;
use BackedEnum;
use Filament\Actions\EditAction;
use Filament\Forms\Components\ColorPicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\ColorColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use UnitEnum;

class CategoryResource extends Resource
{
    protected static ?string $model = Category::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedTag;

    protected static string|UnitEnum|null $navigationGroup = 'Catálogo';

    protected static ?string $modelLabel = 'categoría';

    protected static ?string $pluralModelLabel = 'categorías';

    protected static ?int $navigationSort = 1;

    /** Iconos disponibles en la app Flutter. */
    public const ICONS = [
        'restaurant' => 'Restaurante',
        'pizza' => 'Pizza',
        'burger' => 'Hamburguesa',
        'coffee' => 'Café',
        'pharmacy' => 'Farmacia',
        'market' => 'Supermercado',
        'liquor' => 'Licorería',
        'pets' => 'Mascotas',
        'store' => 'Tienda',
        'dessert' => 'Postres',
    ];

    public static function form(Schema $schema): Schema
    {
        return $schema->components([
            TextInput::make('name')->label('Nombre')->required(),
            Select::make('icon')->label('Icono')->options(self::ICONS)->required()->default('store'),
            ColorPicker::make('color')->default('#10B981'),
            TextInput::make('sort')->label('Orden')->numeric()->default(0),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->defaultSort('sort')
            ->reorderable('sort')
            ->columns([
                ColorColumn::make('color'),
                TextColumn::make('name')->label('Nombre')->searchable(),
                TextColumn::make('icon')->label('Icono')->formatStateUsing(fn ($state) => self::ICONS[$state] ?? $state),
                TextColumn::make('businesses_count')->label('Negocios')->counts('businesses'),
            ])
            ->recordActions([
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCategories::route('/'),
            'create' => CreateCategory::route('/create'),
            'view' => ViewCategory::route('/{record}'),
            'edit' => EditCategory::route('/{record}/edit'),
        ];
    }
}
