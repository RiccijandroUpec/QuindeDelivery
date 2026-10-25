<?php

namespace App\Filament\Pages;

use App\Models\Setting;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Components\Actions;
use Filament\Schemas\Components\EmbeddedSchema;
use Filament\Schemas\Components\Form;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Text;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use UnitEnum;

/** Tarifas de la plataforma: lo que gana Colibrí en cada pedido. */
class PlatformSettings extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCog6Tooth;

    protected static string|UnitEnum|null $navigationGroup = 'Ventas';

    protected static ?string $navigationLabel = 'Tarifas';

    protected static ?string $title = 'Tarifas de la plataforma';

    protected static ?string $slug = 'tarifas';

    public ?array $data = [];

    public function mount(): void
    {
        $this->form->fill([
            'service_fee' => Setting::float('service_fee'),
            'driver_share' => Setting::float('driver_share'),
        ]);
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->statePath('data')
            ->components([
                Section::make('Cliente')
                    ->description('Se suma al total de cada pedido.')
                    ->schema([
                        TextInput::make('service_fee')->label('Tarifa de servicio por pedido')
                            ->numeric()->prefix('$')->minValue(0)->maxValue(20)->step(0.05)->required(),
                    ]),
                Section::make('Envío')
                    ->description('Cómo se reparte el costo de envío de cada pedido.')
                    ->schema([
                        TextInput::make('driver_share')->label('Parte del repartidor')
                            ->numeric()->suffix('%')->minValue(0)->maxValue(100)->required()->live(debounce: 400),
                        Text::make(fn ($get) => 'Con un envío de $1.50: el repartidor recibe $'
                            .number_format(1.5 * (float) $get('driver_share') / 100, 2).' y la plataforma $'
                            .number_format(1.5 * (1 - (float) $get('driver_share') / 100), 2).'.'),
                    ]),
                Section::make('Negocios')
                    ->schema([
                        Text::make('La comisión sobre las ventas se configura en cada negocio (Catálogo → Negocios → Comisión).'),
                    ]),
            ]);
    }

    public function content(Schema $schema): Schema
    {
        return $schema->components([
            Form::make([EmbeddedSchema::make('form')])
                ->livewireSubmitHandler('save')
                ->footer([
                    Actions::make([Action::make('save')->label('Guardar')->submit('save')]),
                ]),
        ]);
    }

    public function save(): void
    {
        Setting::put($this->form->getState());
        Notification::make()->title('Tarifas guardadas')->body('Se aplican a los pedidos nuevos.')->success()->send();
    }
}
