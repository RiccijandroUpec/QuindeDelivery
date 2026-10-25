<?php

namespace App\Filament\Resources\Users;

use App\Filament\Resources\Users\Pages\CreateUser;
use App\Filament\Resources\Users\Pages\EditUser;
use App\Filament\Resources\Users\Pages\ListUsers;
use App\Filament\Resources\Users\Pages\ViewUser;
use App\Models\User;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Columns\ToggleColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class UserResource extends Resource
{
    protected static ?string $model = User::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static ?string $modelLabel = 'usuario';

    protected static ?string $pluralModelLabel = 'usuarios';

    protected static ?int $navigationSort = 5;

    public static function form(Schema $schema): Schema
    {
        return $schema->columns(2)->components([
            TextInput::make('name')->label('Nombre')->required(),
            TextInput::make('email')->label('Correo')->email()->required()->unique(ignoreRecord: true),
            Select::make('role')->label('Rol')->options(User::ROLES)->required()->default('cliente')->live(),
            TextInput::make('phone')->label('Teléfono')->tel(),
            TextInput::make('vehicle')->label('Vehículo / placa')
                ->visible(fn ($get) => $get('role') === 'repartidor'),
            Select::make('business_id')->label('Negocio')
                ->relationship('business', 'name')
                ->searchable()
                ->preload()
                ->visible(fn ($get) => $get('role') === 'negocio')
                ->required(fn ($get) => $get('role') === 'negocio'),
            TextInput::make('password')
                ->label('Contraseña')
                ->password()
                ->revealable()
                ->required(fn (string $operation) => $operation === 'create')
                ->dehydrated(fn ($state) => filled($state))
                ->helperText(fn (string $operation) => $operation === 'edit' ? 'Déjalo vacío para no cambiarla.' : null),
            Toggle::make('active')->label('Activo')->default(true),
        ]);
    }

    public static function table(Table $table): Table
    {
        return $table
            ->columns([
                TextColumn::make('name')->label('Nombre')->searchable(),
                TextColumn::make('email')->label('Correo')->searchable(),
                TextColumn::make('role')->label('Rol')->badge()
                    ->formatStateUsing(fn ($state) => User::ROLES[$state] ?? $state)
                    ->color(fn ($state) => match ($state) {
                        'admin' => 'danger',
                        'repartidor' => 'info',
                        'negocio' => 'warning',
                        default => 'primary',
                    }),
                TextColumn::make('business.name')->label('Negocio')->placeholder('-')->toggleable(),
                TextColumn::make('phone')->label('Teléfono'),
                TextColumn::make('approved_at')->label('Aprobado')
                    ->state(fn (User $record) => $record->isPendingApproval() ? 'En revisión' : 'Sí')
                    ->badge()
                    ->color(fn (User $record) => $record->isPendingApproval() ? 'warning' : 'success'),
                ToggleColumn::make('active')->label('Activo'),
                TextColumn::make('created_at')->label('Registro')->date('d/m/Y')->sortable(),
            ])
            ->filters([
                SelectFilter::make('role')->label('Rol')->options(User::ROLES),
            ])
            ->recordActions([
                Action::make('approve')
                    ->label('Aprobar')
                    ->icon(Heroicon::OutlinedCheckBadge)
                    ->color('success')
                    ->visible(fn (User $record) => $record->isPendingApproval())
                    ->requiresConfirmation()
                    ->action(function (User $record) {
                        $record->update(['approved_at' => now()]);
                        Notification::make()->title("{$record->name} ya puede repartir")->success()->send();
                    }),
                EditAction::make(),
            ]);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListUsers::route('/'),
            'create' => CreateUser::route('/create'),
            'view' => ViewUser::route('/{record}'),
            'edit' => EditUser::route('/{record}/edit'),
        ];
    }
}
