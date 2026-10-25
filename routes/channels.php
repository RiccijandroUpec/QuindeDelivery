<?php

use App\Models\Order;
use App\Models\User;
use Illuminate\Support\Facades\Broadcast;

Broadcast::channel('App.Models.User.{id}', function ($user, $id) {
    return (int) $user->id === (int) $id;
});

// Un pedido lo escuchan su cliente, su negocio, su repartidor y los repartidores que pueden tomarlo.
Broadcast::channel('orders.{order}', function (User $user, Order $order) {
    return $order->user_id === $user->id
        || $order->driver_id === $user->id
        || ($user->role === 'negocio' && $user->business_id === $order->business_id)
        || ($user->isDriver() && ! $user->isPendingApproval() && $order->driver_id === null);
});

Broadcast::channel('business.{businessId}', function (User $user, int $businessId) {
    return $user->role === 'negocio' && $user->business_id === $businessId;
});

Broadcast::channel('drivers', function (User $user) {
    return $user->isDriver() && ! $user->isPendingApproval();
});
