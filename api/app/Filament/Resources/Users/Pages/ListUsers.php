<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use App\Models\User;
use Filament\Actions\CreateAction;
use Filament\Resources\Pages\ListRecords;
use Filament\Schemas\Components\Tabs\Tab;

class ListUsers extends ListRecords
{
    protected static string $resource = UserResource::class;

    protected function getHeaderActions(): array
    {
        return [
            CreateAction::make(),
        ];
    }

    public function getTabs(): array
    {
        $pending = fn ($q) => $q->where('role', 'repartidor')->whereNull('approved_at');

        return [
            'todos' => Tab::make('Todos'),
            'revision' => Tab::make('Repartidores por aprobar')
                ->badge($pending(User::query())->count() ?: null)
                ->badgeColor('warning')
                ->modifyQueryUsing($pending),
        ];
    }
}
