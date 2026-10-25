<?php

namespace App\Events;

use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/** Nueva posición del repartidor para el mapa del cliente. */
class DriverMoved implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public int $orderId, public float $lat, public float $lng) {}

    public function broadcastOn(): array
    {
        return [new PrivateChannel("orders.{$this->orderId}")];
    }

    public function broadcastAs(): string
    {
        return 'driver.moved';
    }

    public function broadcastWith(): array
    {
        return ['lat' => $this->lat, 'lng' => $this->lng];
    }
}
