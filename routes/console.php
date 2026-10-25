<?php

use App\Models\Order;
use Illuminate\Foundation\Inspiring;
use Illuminate\Support\Facades\Artisan;
use Illuminate\Support\Facades\Schedule;

Artisan::command('inspire', function () {
    $this->comment(Inspiring::quote());
})->purpose('Display an inspiring quote');

Artisan::command('orders:expire', function () {
    $count = Order::where('status', 'pendiente')
        ->where('created_at', '<', now()->subMinutes(Order::PENDING_TIMEOUT))
        ->update(['status' => 'cancelado', 'cancel_reason' => 'El negocio no respondió a tiempo.']);
    $this->info("Pedidos vencidos: {$count}");
})->purpose('Cancela pedidos que el negocio no aceptó a tiempo');

Schedule::command('orders:expire')->everyMinute();
