<?php

namespace App\Filament\Resources\Users\Pages;

use App\Filament\Resources\Users\UserResource;
use Filament\Resources\Pages\CreateRecord;

class CreateUser extends CreateRecord
{
    protected static string $resource = UserResource::class;

    /** Las cuentas creadas por el admin quedan aprobadas. */
    protected function mutateFormDataBeforeCreate(array $data): array
    {
        return [...$data, 'approved_at' => now()];
    }
}
