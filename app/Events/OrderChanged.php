<?php

namespace App\Events;

use App\Models\Order;
use Illuminate\Broadcasting\PrivateChannel;
use Illuminate\Contracts\Broadcasting\ShouldBroadcastNow;
use Illuminate\Foundation\Events\Dispatchable;

/**
 * Avisa en tiempo real que un pedido cambió. Solo lleva el id y el estado:
 * la app vuelve a pedir el detalle por la API, que ya valida permisos.
 */
class OrderChanged implements ShouldBroadcastNow
{
    use Dispatchable;

    public function __construct(public Order $order) {}

    public function broadcastOn(): array
    {
        $channels = [
            new PrivateChannel("orders.{$this->order->id}"),
            new PrivateChannel("business.{$this->order->business_id}"),
        ];
        if (in_array($this->order->status, Order::AVAILABLE_FOR_DRIVER) || $this->order->wasChanged('driver_id')) {
            $channels[] = new PrivateChannel('drivers');
        }

        return $channels;
    }

    public function broadcastAs(): string
    {
        return 'order.changed';
    }

    public function broadcastWith(): array
    {
        return ['id' => $this->order->id, 'status' => $this->order->status];
    }
}
