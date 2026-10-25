<?php

namespace App\Filament\Resources\Products;

use App\Filament\Resources\Products\Pages\CreateProduct;
use App\Filament\Resources\Products\Pages\EditProduct;
use App\Filament\Resources\Products\Pages\ListProducts;
use App\Filament\Resources\Products\Pages\ViewProduct;
use App\Models\Product;
use BackedEnum;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\FileUpload;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use UnitEnum;

class ProductResource extends Resource
{
    protected static ?string $model = Product::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCube;

    protected static string|UnitEnum|null $navigationGroup = 'Catálogo';

    protected static ?string $modelLabel = 'producto';

    protected static ?string $pluralModelLabel = 'productos';

    protected static ?int $navigationSort = 3;

    /** Campos compartidos con el gestor de productos dentro de cada negocio. */
    public static function fields(bool $withBusiness = true): array
    {
        return array_values(array_filter([
            $withBusiness ? Select::make('business_id')
                ->label('Negocio')
                ->relationship('business', 'name')
                ->searchable()
                ->preload()
                ->required() : null,
            TextInput::make('name')->label('Nombre')->required(),
            TextInput::make('section')->label('Sección del menú')->default('General')->required()
                ->helperText('Ej: Entradas, Platos fuertes, Bebidas'),
            TextInput::make('price')->label('Precio')->numeric()->prefix('$')->required(),
            Toggle::make('available')->label('Disponible')->default(true)->inline(false),
            Textarea::make('description')->label('Descripción')->columnSpanFull(),
            FileUpload::make('image')->label('Imagen')->image()->disk('public')->directory('products')->columnSpanFull(),
        ]));
    }

    public static function columns(bool $withBusiness = true): array
    {
        return array_values(array_filter([
            ImageColumn::make('image')->label('')->disk('public')->square(),
            TextColumn::make('name')->label('Nombre')->searchable()->sortable(),
            $withBusiness ? TextColumn::make('business.name')->label('Negocio')->sortable() : null,
            TextColumn::make('section')->label('Sección')->badge()->color('gray'),
            TextColumn::make('price')->label('Precio')->money('USD')->sortable(),
            ToggleColumn::make('available')->label('Disponible'),
        ]));
    }

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components(self::fields());
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns(self::columns())
            ->filters([
                SelectFilter::make('business_id')->label('Negocio')->relationship('business', 'name'),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListProducts::route('/'),
            'create' => CreateProduct::route('/create'),
            'view' => ViewProduct::route('/{record}'),
            'edit' => EditProduct::route('/{record}/edit'),
        ];
    }
}
