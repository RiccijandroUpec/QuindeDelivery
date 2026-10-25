<?php

namespace App\Filament\Pages;

use App\Filament\Settlements\BusinessSettlements;
use App\Filament\Settlements\DriverEarnings;
use App\Filament\Settlements\PlatformRevenue;
use BackedEnum;
use Filament\Pages\Page;
use Filament\Support\Icons\Heroicon;
use UnitEnum;

class Settlements extends Page
{
    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedBanknotes;

    protected static string|UnitEnum|null $navigationGroup = 'Ventas';

    protected static ?string $navigationLabel = 'Liquidaciones';

    protected static ?string $title = 'Liquidaciones';

    protected static ?string $slug = 'liquidaciones';

    protected function getHeaderWidgets(): array
    {
        return [PlatformRevenue::class, BusinessSettlements::class, DriverEarnings::class];
    }

    public function getHeaderWidgetsColumns(): int|array
    {
        return 1;
    }
}
